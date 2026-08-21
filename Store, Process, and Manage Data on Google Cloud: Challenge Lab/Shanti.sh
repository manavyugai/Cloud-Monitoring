#!/bin/bash
# Solution Script for Store, Process, and Manage Data on Google Cloud: Challenge Lab (ARC100)

set -e

# Prompt user for variable values assigned in the lab instructions
read -p "Enter BUCKET_NAME: " BUCKET_NAME
read -p "Enter TOPIC_NAME: " TOPIC_NAME
read -p "Enter FUNCTION_NAME: " FUNCTION_NAME
read -p "Enter REGION (e.g., us-central1): " REGION

# Get current GCP Project ID
PROJECT_ID=$(gcloud config get-value project)

echo "=========================================="
echo "Starting lab setup for Project: $PROJECT_ID"
echo "=========================================="

# -------------------------------------------------------------------------
# Task 1: Create a Bucket
# -------------------------------------------------------------------------
echo "[1/4] Creating Cloud Storage Bucket..."
gsutil mb -l $REGION gs://$BUCKET_NAME/

# -------------------------------------------------------------------------
# Task 2: Create a Pub/Sub Topic
# -------------------------------------------------------------------------
echo "[2/4] Creating Pub/Sub Topic..."
gcloud pubsub topics create $TOPIC_NAME

# -------------------------------------------------------------------------
# Task 3: Create the Thumbnail Cloud Run Function
# -------------------------------------------------------------------------
echo "[3/4] Preparing source code and deploying Cloud Function..."

mkdir -p ~/thumbnail-func
cd ~/thumbnail-func

# Write index.js with dynamically populated cloudEvent, bucket, and topic values
cat << EOF > index.js
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('$FUNCTION_NAME', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(\`Event: \${JSON.stringify(event)}\`);
  console.log(\`Hello \${event.bucket}\`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "$TOPIC_NAME";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1);

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      console.log(\`Processing Original: gs://\${bucketName}/\${fileName}\`);
      const gcsObject = bucket.file(fileName);
      const newFilename = \`\${filename_without_ext}_64x64_thumbnail.\${filename_ext}\`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: {
            contentType: \`image/\${filename_ext}\`,
          },
        });

        console.log(\`Success: \${fileName} → \${newFilename}\`);

        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });

        console.log(\`Message published to \${topicName}\`);
      } catch (err) {
        console.error(\`Error: \${err}\`);
      }
    } else {
      console.log(\`gs://\${bucketName}/\${fileName} is not an image I can handle\`);
    }
  } else {
    console.log(\`gs://\${bucketName}/\${fileName} already has a thumbnail\`);
  }
});
EOF

# Write package.json
cat << 'EOF' > package.json
{
  "name": "thumbnails",
  "version": "1.0.0",
  "description": "Create Thumbnail of uploaded image",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/pubsub": "^2.0.0",
    "@google-cloud/storage": "^6.11.0",
    "sharp": "^0.32.1"
  },
  "devDependencies": {},
  "engines": {
    "node": ">=4.3.2"
  }
}
EOF

# Ensure Eventarc & Cloud Run service accounts have required permissions
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
STORAGE_SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_ID)

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$STORAGE_SERVICE_ACCOUNT" \
    --role="roles/pubsub.publisher" > /dev/null

# Deploy 2nd Gen Cloud Function (Cloud Run Function) with Node.js 22 runtime
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --source=. \
  --entry-point=$FUNCTION_NAME \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$BUCKET_NAME"

# -------------------------------------------------------------------------
# Task 4: Test Infrastructure
# -------------------------------------------------------------------------
echo "[4/4] Uploading test image to bucket..."
curl -sO https://storage.googleapis.com/cloud-training/arc101/travel.jpg
gsutil cp travel.jpg gs://$BUCKET_NAME/

echo "=========================================="
echo "Setup complete! Check your lab progress."
echo "=========================================="
