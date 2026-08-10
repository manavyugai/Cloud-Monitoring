# Consuming Customer Specific Datasets from Data Sharing Partners using BigQuery
**Lab Reference:** [GSP1043](https://www.cloudskillsboost.google/focuses/42015?parent=catalog)

---
## 🚀 Quick Solution Guide
Follow the steps below sequentially in their respective Google Cloud Shell environments to complete the lab setup.

### 1️⃣ Data Sharing Partner Console

Open **Cloud Shell** in the **Data Sharing Partner Project** and run:

```bash
curl -LO [https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Consuming%20Customer%20Specific%20Datasets%20from%20Data%20Sharing%20Partners%20using%20BigQuery/gsp1043-1.sh](https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Consuming%20Customer%20Specific%20Datasets%20from%20Data%20Sharing%20Partners%20using%20BigQuery/gsp1043-1.sh)
chmod +x *.sh
./gsp1043-1.sh
```
### 2️⃣ Data Publisher Console
### Switch to Cloud Shell in the Data Publisher Project and run:

```
curl -LO https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Consuming%20Customer%20Specific%20Datasets%20from%20Data%20Sharing%20Partners%20using%20BigQuery/gsp1043-2.sh

sudo chmod +x *.sh

./*.sh
```

### 3️⃣ Customer (Data Twin) Console
Switch to Cloud Shell in the Customer (Data Twin) Project and run:

```
curl -LO https://raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/refs/heads/main/Consuming%20Customer%20Specific%20Datasets%20from%20Data%20Sharing%20Partners%20using%20BigQuery/gsp1043-3.sh

sudo chmod +x *.sh

./*.sh
```

# 🎉 Congratulations!
You have successfully executed the data-sharing setup across all required project environments!
