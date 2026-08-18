#!/bin/bash
set -e

# Auto-detect Project ID and Auth Token
export PROJECT_ID=$(gcloud config get-value project)
export ACCESS_TOKEN=$(gcloud auth print-access-token)
export LOCATION="us"

echo "=========================================="
echo "Project ID detected: $PROJECT_ID"
echo "=========================================="

# Prompt for the bucket names and sanitize them (remove gs:// or trailing slashes)
read -p "Enter REDACT bucket name: " RAW_REDACT
read -p "Enter INPUT bucket name: " RAW_INPUT
read -p "Enter OUTPUT bucket name: " RAW_OUTPUT

export REDACT_BUCKET=$(echo "$RAW_REDACT" | sed 's|^gs://||; s|/*$||')
export INPUT_BUCKET=$(echo "$RAW_INPUT" | sed 's|^gs://||; s|/*$||')
export OUTPUT_BUCKET=$(echo "$RAW_OUTPUT" | sed 's|^gs://||; s|/*$||')

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
                "maskingCharacter": "#"
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
                "newValue": {
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
echo ">>> [Task 3] Configuring DLP Job Trigger and running inspection..."

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

# Run a DLP Inspect Job immediately to populate the output bucket
cat << EOF > inspect_job.json
{
  "jobId": "dlp_run_job_$(date +%s)",
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
  }
}
EOF

curl -s -X POST \
  "https://dlp.googleapis.com/v2/projects/${PROJECT_ID}/locations/${LOCATION}/dlpJobs" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @inspect_job.json

echo ""
echo ">>> Waiting 25 seconds for DLP job processing to finish..."
sleep 25

echo ">>> All tasks completed successfully!"
