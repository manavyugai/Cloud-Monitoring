#!/bin/bash
set -e

# Auto-detect Project ID and Auth Token
export PROJECT_ID=$(gcloud config get-value project)
export ACCESS_TOKEN=$(gcloud auth print-access-token)
export LOCATION="us"

echo "=========================================="
echo "Project ID detected: $PROJECT_ID"
echo "=========================================="

# Prompt for the yellow-highlighted bucket variables
read -p "Enter REDACT bucket name (e.g. qwiklabs-gcp-04-179bd42f50c1-redact): " REDACT_BUCKET
read -p "Enter INPUT bucket name (e.g. qwiklabs-gcp-04-179bd42f50c1-input): " INPUT_BUCKET
read -p "Enter OUTPUT bucket name (e.g. qwiklabs-gcp-04-179bd42f50c1-output): " OUTPUT_BUCKET

echo ""
echo ">>> [Task 1] Redacting sensitive data from text content..."

cat << 'EOF' > redact-request.json
{
  "item": {
    "value": "Please update my records with the following information:\n Email address: foo@example.com, \nNational Provider Identifier: 1245319599"
  },
  "deidentifyConfig": {
    "infoTypeTransformations": {
      "transformations": [
        {
          "primitiveTransformation": {
            "replaceWithInfoTypeConfig": {}
          }
        }
      ]
    }
  },
  "inspectConfig": {
    "infoTypes": [
      {
        "name": "EMAIL_ADDRESS"
      },
      {
        "name": "US_HEALTHCARE_NPI"
      }
    ]
  }
}
EOF

# Call DLP API to de-identify content and save response
curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/content:deidentify" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @redact-request.json > redact-response.txt

# Upload response to Redact Bucket
gcloud storage cp redact-response.txt gs://${REDACT_BUCKET}/

echo ">>> [Task 2] Creating DLP inspection and de-identification templates..."

# 1. Structured Data De-identify Template
cat << 'EOF' > structured_template.json
{
  "deidentifyTemplate": {
    "displayName": "structured_data_template",
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              { "name": "bank name" },
              { "name": "zip code" }
            ],
            "primitiveTransformation": {
              "characterMaskConfig": {
                "maskingChar": "#"
              }
            }
          },
          {
            "fields": [
              { "name": "message" }
            ],
            "infoTypeTransformations": {
              "transformations": [
                {
                  "primitiveTransformation": {
                    "replaceWithInfoTypeConfig": {}
                  }
                }
              ]
            }
          }
        ]
      }
    }
  },
  "templateId": "structured_data_template"
}
EOF

curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/deidentifyTemplates" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @structured_template.json

# 2. Unstructured Data De-identify Template
cat << 'EOF' > unstructured_template.json
{
  "deidentifyTemplate": {
    "displayName": "unstructured_data_template",
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "primitiveTransformation": {
              "replaceConfig": {
                "newTransformationValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          }
        ]
      }
    }
  },
  "templateId": "unstructured_data_template"
}
EOF

curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/deidentifyTemplates" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @unstructured_template.json

echo ""
echo ">>> [Task 3] Configuring and triggering DLP Job Trigger..."

cat << EOF > job_trigger.json
{
  "jobTrigger": {
    "displayName": "dlp_job",
    "inspectJob": {
      "storageConfig": {
        "cloudStorageOptions": {
          "fileSet": {
            "url": "gs://${INPUT_BUCKET}/*"
          }
        }
      },
      "actions": [
        {
          "deidentify": {
            "cloudStorageOutput": "gs://${OUTPUT_BUCKET}",
            "transformationConfig": {
              "deidentifyTemplate": "projects/${PROJECT_ID}/locations/${LOCATION}/deidentifyTemplates/unstructured_data_template",
              "structuredDeidentifyTemplate": "projects/${PROJECT_ID}/locations/${LOCATION}/deidentifyTemplates/structured_data_template"
            }
          }
        }
      ]
    },
    "triggers": [
      {
        "schedule": {
          "recurrencePeriodDuration": "604800s"
        }
      }
    ],
    "status": "HEALTHY"
  },
  "triggerId": "dlp_job"
}
EOF

# Create Job Trigger
curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/jobTriggers" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @job_trigger.json

# Activate/Run the trigger immediately
curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/jobTriggers/dlp_job:activate" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json"

echo ""
echo ">>> Waiting 20 seconds for DLP job to process files..."
sleep 20

echo ">>> Done! Please go back and check your progress on all tasks."
