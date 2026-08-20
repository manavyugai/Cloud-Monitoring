```bash
#!/bin/bash

# ==============================
#        COLOR SETTINGS
# ==============================

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

# ==============================
#          UI FUNCTIONS
# ==============================

line() {
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

header() {
    clear
    echo
    echo "${BLUE}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo "${BLUE}${BOLD}║              GCP LAB EXECUTION                  ║${RESET}"
    echo "${BLUE}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
    echo
}

step() {
    echo "${YELLOW}${BOLD}➜ $1${RESET}"
}

success() {
    echo "${GREEN}${BOLD}✔ $1${RESET}"
}

# ==============================
#          START
# ==============================

header

echo "${MAGENTA}${BOLD}Initializing Lab Environment...${RESET}"
line

step "Configuring Compute Region"
gcloud config set compute/region $REGION
success "Region configured"
echo

step "Creating Cloud Storage Bucket"
gsutil mb gs://$DEVSHELL_PROJECT_ID
success "Bucket created"
echo

step "Downloading Ada Lovelace Image"
curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg
success "Image downloaded"
echo

step "Uploading Image to Cloud Storage"
gsutil cp ada.jpg gs://$DEVSHELL_PROJECT_ID
success "Image uploaded"
echo

step "Copying Image from Cloud Storage"
gsutil cp -r gs://$DEVSHELL_PROJECT_ID/ada.jpg .
success "Image copied"
echo

step "Copying Image to image-folder"
gsutil cp gs://$DEVSHELL_PROJECT_ID/ada.jpg gs://$DEVSHELL_PROJECT_ID/image-folder/
success "Image copied to folder"
echo

step "Updating Bucket Access Permissions"
gsutil acl ch -u AllUsers:R gs://$DEVSHELL_PROJECT_ID/ada.jpg
success "Permissions updated"
echo

line
echo
echo "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}║                                                  ║${RESET}"
echo "${GREEN}${BOLD}║        ✓  LAB COMPLETED SUCCESSFULLY  ✓        ║${RESET}"
echo "${GREEN}${BOLD}║                                                  ║${RESET}"
echo "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}All required operations have been executed.${RESET}"
echo
line
```
