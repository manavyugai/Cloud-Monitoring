## Build Google Cloud Infrastructure for AWS Professionals: Challenge Lab



### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### Run the following Commands in CloudShell

```
curl -LO https://raw.githubusercontent.com/manavyugai/Cloud-Monitoring/main/Build%20Google%20Cloud%20Infrastructure%20for%20AWS%20Professionals%20Challenge%20Lab/Mesho.sh
sudo chmod +x Mesho.sh
./Mesho.sh
```

## At last Run this if not getting scorer

```
EXTERNAL_IP=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

gcloud monitoring uptime create griffin-dev-uptime \
  --resource-type=uptime-url \
  --resource-labels=host=$EXTERNAL_IP \
  --path="/" \
  --protocol=http
```
### Congratulations !!!!



