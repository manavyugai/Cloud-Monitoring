clear
# Colors & Styling
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[38;5;51m'
C_AMBER='\033[38;5;214m'
C_GREEN='\033[38;5;82m'
C_PURPLE='\033[38;5;141m'

echo -e "${C_PURPLE}${C_BOLD}"
cat << "EOF"
  ┌───────────────────────────────────────────────────────────┐
  │   ⚡ FULL AUTOMATED CLOUD SQL LAB (TASK 1, 2, 3 & 4)      │
  └───────────────────────────────────────────────────────────┘
EOF
echo -e "${C_RESET}"

# Input Parameters
read -p "➔ Enter Migration user name (e.g., Postgres Migration User): " MIGRATION_USER
read -p "➔ Enter Migrated Cloud SQL Instance ID: " SQL_INSTANCE
read -p "➔ Enter Qwiklabs Student Email: " STUDENT_EMAIL
read -p "➔ Enter Table Name (e.g., orders): " TABLE_NAME
read -p "➔ Enter PITR Retention Days (e.g., 2): " RETENTION_DAYS
echo ""

# Auto Detect Details
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
export VM_NAME=$(gcloud compute instances list --format="value(name)" 2>/dev/null | grep postgres)
export ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format="value(zone)")
export REGION=${ZONE%-*}
export INTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].networkIP)")
export EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo -e "${C_CYAN}⚙️  [TASK 1] VM & Database Prep...${C_RESET}"
gcloud services enable datamigration.googleapis.com servicenetworking.googleapis.com --quiet

gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="sudo apt-get update && sudo apt-get install postgresql-14-pglogical -y
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf .'
sudo su - postgres -c 'gsutil cp gs://cloud-training/gsp918/postgresql_append.conf .'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/pg_hba.conf || cat pg_hba_append.conf >> /etc/postgresql/14/main/pg_hba.conf'
sudo su - postgres -c 'grep -q \"pglogical\" /etc/postgresql/14/main/postgresql.conf || cat postgresql_append.conf >> /etc/postgresql/14/main/postgresql.conf'
sudo systemctl restart postgresql@14-main"

cat << EOF > sql_commands.sql
\c postgres;
CREATE EXTENSION IF NOT EXISTS pglogical;
\c orders;
CREATE EXTENSION IF NOT EXISTS pglogical;
\c postgres;
CREATE USER "${MIGRATION_USER}" PASSWORD 'DMS_1s_cool!';
ALTER DATABASE orders OWNER TO "${MIGRATION_USER}";
ALTER ROLE "${MIGRATION_USER}" WITH REPLICATION;
\c orders;
ALTER TABLE inventory_items ADD PRIMARY KEY (id);
GRANT USAGE ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.tables TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.depend TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_sync_status TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node_interface TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.queue TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_seq TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_table TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.sequence_state TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.subscription TO "${MIGRATION_USER}";
GRANT USAGE ON SCHEMA public TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA public TO "${MIGRATION_USER}";
GRANT SELECT ON public.distribution_centers TO "${MIGRATION_USER}";
GRANT SELECT ON public.inventory_items TO "${MIGRATION_USER}";
GRANT SELECT ON public.order_items TO "${MIGRATION_USER}";
GRANT SELECT ON public.products TO "${MIGRATION_USER}";
GRANT SELECT ON public.users TO "${MIGRATION_USER}";
ALTER TABLE public.distribution_centers OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.inventory_items OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.order_items OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.products OWNER TO "${MIGRATION_USER}";
ALTER TABLE public.users OWNER TO "${MIGRATION_USER}";
\c postgres;
GRANT USAGE ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT ALL ON SCHEMA pglogical TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.tables TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.depend TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.local_sync_status TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.node_interface TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.queue TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_seq TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.replication_set_table TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.sequence_state TO "${MIGRATION_USER}";
GRANT SELECT ON pglogical.subscription TO "${MIGRATION_USER}";
EOF

gcloud compute scp sql_commands.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="sudo su - postgres -c 'psql -f /tmp/sql_commands.sql'"

echo -e "${C_CYAN}🌐 [TASK 1] Creating Connection Profile & Starting Job...${C_RESET}"
gcloud database-migration connection-profiles create postgresql migration-profile \
    --display-name="migration-profile" \
    --region=$REGION \
    --host=$INTERNAL_IP \
    --port=5432 \
    --username="${MIGRATION_USER}" \
    --password="DMS_1s_cool!" --quiet || true

gcloud database-migration migration-jobs create migration-job \
    --location=$REGION \
    --source-connection-profile=projects/$PROJECT_ID/locations/$REGION/connectionProfiles/migration-profile \
    --destination-sql-instance=$SQL_INSTANCE \
    --type=CONTINUOUS \
    --peer-vpc=default --quiet || true

gcloud database-migration migration-jobs start migration-job --location=$REGION --quiet || true

echo -e "${C_AMBER}⏳ [TASK 2] Waiting for Migration Job to sync (60 seconds)...${C_RESET}"
sleep 60

echo -e "${C_CYAN}🚀 [TASK 2] Promoting Cloud SQL Instance...${C_RESET}"
gcloud database-migration migration-jobs promote migration-job --location=$REGION --quiet || true

echo -e "${C_CYAN}🔧 [TASK 3] Patching Instance & Cloud IAM Auth...${C_RESET}"
gcloud sql instances patch $SQL_INSTANCE \
    --database-flags cloudsql.iam_authentication=on \
    --authorized-networks=$EXTERNAL_IP \
    --enable-point-in-time-recovery \
    --retained-transaction-log-days=$RETENTION_DAYS \
    --quiet

gcloud sql users create $STUDENT_EMAIL \
    --instance=$SQL_INSTANCE \
    --type=CLOUD_IAM_USER --quiet || true

export SQL_IP=$(gcloud sql instances describe $SQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")

cat << EOF > iam_grant.sql
GRANT SELECT ON $TABLE_NAME TO "$STUDENT_EMAIL";
EOF

gcloud compute scp iam_grant.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/iam_grant.sql"

cat << EOF > test_iam.sql
SELECT COUNT(*) FROM $TABLE_NAME;
EOF
gcloud sql connect $SQL_INSTANCE --database=orders --user=$STUDENT_EMAIL --quiet < test_iam.sql

echo -e "${C_CYAN}🔄 [TASK 4] Capturing Timestamp & Cloning Instance for PITR...${C_RESET}"
TIME_STAMP=$(date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/')
sleep 5

cat << 'EOF' > insert_row.sql
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
EOF

gcloud compute scp insert_row.sql $VM_NAME:/tmp/ --zone=$ZONE --quiet
gcloud compute ssh $VM_NAME --zone=$ZONE --quiet --command="PGPASSWORD=supersecret! psql -h $SQL_IP -U postgres -d orders -f /tmp/insert_row.sql"

gcloud sql instances clone $SQL_INSTANCE postgres-orders-pitr \
 --point-in-time $TIME_STAMP --quiet

echo -e "\n${C_GREEN}${C_BOLD}🎉 ALL TASKS (1, 2, 3 & 4) COMPLETED DIRECTLY VIA SCRIPT! 🎉${C_RESET}\n"
