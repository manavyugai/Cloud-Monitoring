#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
PINK_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION=us-west1
gcloud config set compute/region $REGION

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Region successfully set to: $REGION${RESET_FORMAT}"
echo
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com

echo
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION
echo "${CYAN_TEXT}${BOLD_TEXT}👤 Change the directory.${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION
echo
curl -sS https://webi.sh/gh | sh 
gh auth login 
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}
echo "${PINK_TEXT}${BOLD_TEXT}📄  Deploy to Cloud Run..${RESET_FORMAT}"
gh repo create  hello-cloudbuild-app --private 
gh repo create  hello-cloudbuild-env --private

echo "${GREEN_TEXT}${BOLD_TEXT}📥 Task 2. Access user identity information...${RESET_FORMAT}"
cd ~
mkdir hello-cloudbuild-app

echo "${YELLOW_TEXT}${BOLD_TEXT}📦  Deploy to Cloud Run...${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Task 3. Use cryptographic verification..${RESET_FORMAT}"
cd ~/hello-cloudbuild-app
echo
export REGION=us-west1
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

echo
PROJECT_ID=$(gcloud config get-value project)
echo
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"

echo
cd ~/hello-cloudbuild-app
echo
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
echo
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .
echo
i. Click **Install Google Cloud Build**. Install the Cloud Build GitHub App in your personal account. Permit the installation using your GitHub account.

ii. Under **Repository access**. Choose **Only select repositories**. Click the **Select the repositories** menu and select **_[your-github-username]_/hello-cloudbuild-app** and **_[your-github-username]_/hello-cloudbuild-env**.

iii. Click **Install**.

echo
echo "${PINK_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${PINK_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo
