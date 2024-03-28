# Update env variables here
export REGION="us-central1"
export ZONE="us-central1-a"
export DATASTORE_ID=genwealth_1711471248274 # Datastore ID used by Vertex S&C
export LOCAL_IPV4="67.79.68.21"

# Keep all defaults below
export PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
export ALLOYDB_CLUSTER="alloydb-cluster"
export ALLOYDB_INSTANCE="alloydb-instance"
export ALLOYDB_IP=$(gcloud alloydb instances describe $ALLOYDB_INSTANCE --cluster=$ALLOYDB_CLUSTER --region=$REGION --view=BASIC --format=json | jq -r .ipAddress) || echo "AlloyDB Instance doesn't exist yet"
export ALLOYDB_PASSWORD=$(gcloud secrets versions access latest --secret="alloydb-password-$PROJECT_ID")
export PGADMIN_USER="demouser@genwealth.com"
export PGADMIN_PASSWORD=$(gcloud secrets versions access latest --secret="pgadmin-password-$PROJECT_ID")
export PGPORT=5432
export PGDATABASE=ragdemos
export PGUSER=postgres
export PGHOST=${ALLOYDB_IP}
export PGPASSWORD=${ALLOYDB_PASSWORD}
export PROSPECTUS_BUCKET=${PROJECT_ID}-docs # GCS Bucket for storing pro
export VPC_NETWORK=demo-vpc
export VPC_SUBNET=$VPC_NETWORK
export VPC_NAME=$VPC_NETWORK
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export GCE_INSTANCE="pgadmin"
export ORGANIZATION=$(gcloud projects get-ancestors ${PROJECT_ID} --format=json | jq -r '.[] | select(.type == "organization").id')

