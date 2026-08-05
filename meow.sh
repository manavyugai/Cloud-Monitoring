#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE MANAVYUG AI- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


# Prompt user for Zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Please Enter Your Zone:${RESET_FORMAT}"
gcloud services enable networkconnectivity.googleapis.com


echo "${CYAN_TEXT}${BOLD_TEXT}Creating a new VM instance... Please wait.${RESET_FORMAT}"

# Create the instance with the necessary metadata and tags
gcloud network-connectivity hubs create ncc-hub

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a firewall rule to allow HTTP traffic...${RESET_FORMAT}"

# Create firewall rule to allow incoming HTTP traffic on port 80
gcloud config set accessibility/screen_reader false
gcloud compute networks subnets list --network=vpc1-ncc

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating SSH keys...${RESET_FORMAT}"

# Generate SSH keys
gcloud network-connectivity spokes linked-vpc-network create vpc1-spoke1 \
--hub=ncc-hub \
--vpc-network=vpc1-ncc \
--exclude-export-ranges=10.1.2.0/24 \
--global

echo "${CYAN_TEXT}${BOLD_TEXT}Installing Apache and PHP on the VM...${RESET_FORMAT}"

gcloud  network-connectivity spokes linked-vpc-network create vpc2-spoke2 \
--hub=ncc-hub \
--vpc-network=vpc2-ncc \
--exclude-export-ranges=10.3.3.0/24 \
--global

echo "${GREEN_TEXT}${BOLD_TEXT}Fetching Instance ID...${RESET_FORMAT}"

gcloud compute networks subnets describe vpc2-ncc-subnet1 \
--region=REGION \
--project=PROJECT_ID \
--format="value(ipCidrRange)"
echo "${BLUE_TEXT}${BOLD_TEXT}Setting up Uptime Monitoring...${RESET_FORMAT}"

gcloud compute addresses create cloudsql-psc \
--project=PROJECT_ID \
--region=REGION \
--subnet=vpc2-ncc-subnet1 \
--addresses=10.2.2.70


echo "${YELLOW_TEXT}${BOLD_TEXT}Creating an email notification channel...${RESET_FORMAT}"

gcloud compute addresses list \
--project=PROJECT_ID \
--filter="name=cloudsql-psc"






echo "${CYAN_TEXT}${BOLD_TEXT}Fetching channel ID...${RESET_FORMAT}"

gcloud compute forwarding-rules create cloudsql-psc-ep \
--address=cloudsql-psc \
--project=PROJECT_ID \
--region=REGION \
--network=vpc2-ncc  \
--target-service-attachment=
--allow-psc-global-access

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating an alert policy for network traffic...${RESET_FORMAT}"

cat > app-engine-error-percent-policy.json <<EOF_END
{
  "displayName": "Inbound Traffic Alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - Network traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/interface/traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "60s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 500
      }
    }
  ],
  "alertStrategy": {},
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END


gcloud alpha monitoring policies create --policy-from-file="app-engine-error-percent-policy.json"


INSTANCE_ID=$(gcloud compute instances describe lamp-1-vm --zone=$ZONE --format='value(id)')

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@ManavYugAI${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
echo
