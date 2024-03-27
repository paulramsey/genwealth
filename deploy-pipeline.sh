# Load env variables
source ./env.sh

# Permissions for cloud functions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/aiplatform.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/alloydb.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/alloydb.client"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/alloydb.databaseUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/discoveryengine.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/documentai.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/eventarc.eventReceiver"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/eventarc.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/ml.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/pubsub.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/serviceusage.serviceUsageConsumer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.admin"


# pubsub access for Cloud Function GCS trigger
SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $PROJECT_ID)"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role='roles/pubsub.publisher'

# Create GCS buckets
gcloud storage buckets create gs://${PROJECT_ID}-docs --location=${REGION} \
    --project=${PROJECT_ID} --uniform-bucket-level-access

gcloud storage buckets create gs://${PROJECT_ID}-docs-metadata --location=${REGION} \
    --project=${PROJECT_ID} --uniform-bucket-level-access

gcloud storage buckets create gs://${PROJECT_ID}-doc-ai --location=${REGION} \
    --project=${PROJECT_ID} --uniform-bucket-level-access

# Create pubsub topic
gcloud pubsub topics create ${PROJECT_ID}-doc-ready --project=${PROJECT_ID}

# Create VPC connector for cloud function
gcloud compute networks vpc-access connectors create vpc-connector --region=${REGION} \
    --network=demo-vpc \
    --range=10.8.0.0/28 \
    --project=${PROJECT_ID} \
    --machine-type=e2-micro 

# Create Document AI processor
echo '{"type": "OCR_PROCESSOR","displayName": "document-text-extraction"}' > request.json
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @request.json \
    "https://us-documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors"

DOC_AI_PROCESSOR_NAME=$(curl -X GET \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://us-documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors" | \
    jq '.processors | .[] | select(.displayName=="document-text-extraction").name')

DOC_AI_PROCESSOR_ID=${DOC_AI_PROCESSOR_NAME##*/}
DOC_AI_PROCESSOR_ID=${DOC_AI_PROCESSOR_ID: 0:-1}

# Create functions
gcloud functions deploy process-pdf \
--gen2 \
--region=${REGION} \
--runtime=python311 \
--source="./function-scripts/process-pdf" \
--entry-point="process_pdf" \
--set-env-vars="REGION=${REGION},ZONE=${ZONE},PROJECT_ID=${PROJECT_ID},PROCESSOR_ID=${DOC_AI_PROCESSOR_ID},IP_TYPE=private" \
--set-secrets "ALLOYDB_PASSWORD=alloydb-password-${PROJECT_ID}:1" \
--egress-settings=private-ranges-only \
--vpc-connector=vpc-connector \
--timeout=540s \
--run-service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--trigger-service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--concurrency=1 \
--max-instances=100 \
--ingress-settings=all \
--memory=2gi \
--cpu=2000m \
--trigger-bucket="${PROJECT_ID}-docs"

gcloud functions deploy analyze-prospectus \
--gen2 \
--region=${REGION} \
--runtime=python311 \
--source="./function-scripts/analyze-prospectus" \
--entry-point="analyze_prospectus" \
--set-env-vars="REGION=${REGION},ZONE=${ZONE},PROJECT_ID=${PROJECT_ID}" \
--set-secrets "ALLOYDB_PASSWORD=alloydb-password-${PROJECT_ID}:1" \
--egress-settings=private-ranges-only \
--vpc-connector=vpc-connector \
--timeout=540s \
--run-service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--trigger-service-account="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
--concurrency=1 \
--max-instances=100 \
--ingress-settings=all \
--memory=2gi \
--cpu=2000m \
--trigger-topic="${PROJECT_ID}-doc-ready"
