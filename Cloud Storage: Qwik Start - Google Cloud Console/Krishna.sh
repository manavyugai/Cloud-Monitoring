```bash
#!/bin/bash

# ============================================================
#              GCP CLOUD STORAGE AUTOMATION
# ============================================================

# ---------- Colors ----------
RESET=$'\033[0m'
BOLD=$'\033[1m'

RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

clear

# ---------- Header ----------
echo
echo "${BLUE}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo "${BLUE}${BOLD}║              GCP CLOUD STORAGE SETUP                    ║${RESET}"
echo "${BLUE}${BOLD}╠══════════════════════════════════════════════════════════╣${RESET}"
echo "${BLUE}${BOLD}║              Initializing deployment...                 ║${RESET}"
echo "${BLUE}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo

# ---------- Project Detection ----------
echo "${CYAN}${BOLD}[1/4]${RESET} Detecting Google Cloud project..."

export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN}✔ Project detected:${RESET} ${WHITE}${BOLD}${PROJECT_ID}${RESET}"
echo

# ---------- Create Bucket ----------
echo "${CYAN}${BOLD}[2/4]${RESET} Creating Cloud Storage bucket..."

gsutil mb -l "$REGION" -c Standard "gs://$PROJECT_ID"

echo "${GREEN}✔ Bucket created successfully${RESET}"
echo

# ---------- Download File ----------
echo "${CYAN}${BOLD}[3/4]${RESET} Downloading required file..."

curl -O https://github.com/gcpsolution99/GCP-solution/blob/main/kitten.png

echo "${GREEN}✔ File downloaded${RESET}"
echo

# ---------- Upload File ----------
echo "${CYAN}${BOLD}[4/4]${RESET} Uploading file to Cloud Storage..."

gsutil cp kitten.png "gs://$PROJECT_ID/kitten.png"

echo "${GREEN}✔ File uploaded successfully${RESET}"
echo

# ---------- Public Access ----------
echo "${YELLOW}Configuring public object access...${RESET}"

gsutil iam ch allUsers:objectViewer "gs://$PROJECT_ID"

echo "${GREEN}✔ Public access configured${RESET}"
echo

# ---------- Completion ----------
echo "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║                  ✓ LAB COMPLETED                        ║${RESET}"
echo "${GREEN}${BOLD}╠══════════════════════════════════════════════════════════╣${RESET}"
echo "${GREEN}${BOLD}║       Cloud Storage setup finished successfully!         ║${RESET}"
echo "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo

echo "${MAGENTA}${BOLD}Thank you for using the automation script.${RESET}"
echo "${YELLOW}${BOLD}Like • Share • Subscribe${RESET}"
echo
```
