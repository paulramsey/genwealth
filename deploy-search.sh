# Load env variables
source ./env.sh

# Enable APIs
gcloud services enable discoveryengine.googleapis.com --project ${PROJECT_ID}

# Call the first API with yes to enable to second necessary API (can't do this directly today)

# Create S&C Datastore (pdf + jsonl metadata)
curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
-H "X-Goog-User-Project: ${PROJECT_ID}" \
"https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores?dataStoreId=search-prospectus-${PROJECT_ID}" \
-d '{
  "displayName": "search-prospectus",
  "industryVertical": "GENERIC",
  "solutionTypes": ["SOLUTION_TYPE_SEARCH"],
  "contentConfig": "CONTENT_REQUIRED",
  "documentProcessingConfig": {
    "defaultParsingConfig": {
      "ocrParsingConfig": {
        "useNativeText": "false"
      }
    }
  }
}'

# Get the data store id
DATA_STORE_ID=$(curl -X GET \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "X-Goog-User-Project: ${PROJECT_ID}" \
https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores | jq -r '.dataStores | .[] | select(.displayName=="search-prospectus").name')
DATA_STORE_ID=${DATA_STORE_ID##*/}

# Import data from gcs
# Ref: https://cloud.google.com/generative-ai-app-builder/docs/create-data-store-es#cloud-storage
 curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://discoveryengine.googleapis.com/v1/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores/${DATA_STORE_ID}/branches/0/documents:import" \
  -d '{
    "gcsSource": {
      "inputUris": ["gs://${DOCS_BUCKET}/directory/*.pdf", "INPUT_FILE_PATTERN_2"],
      "dataSchema": "document",
    }
  }'

# Create S&C App
# Ref: https://cloud.google.com/generative-ai-app-builder/docs/create-engine-es
curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
-H "X-Goog-User-Project: PROJECT_ID" \
"https://discoveryengine.googleapis.com/v1/projects/PROJECT_ID/locations/global/collections/default_collection/engines?engineId=APP_ID" \
-d '{
  "displayName": "APP_DISPLAY_NAME",
  "dataStoreIds": ["DATA_STORE_ID"],
  "solutionType": "SOLUTION_TYPE_SEARCH",
  "searchEngineConfig": {
     "searchTier": "SEARCH_TIER_ENTERPRISE",
     "searchAddOns": ["SEARCH_ADD_ON"]
   }
}'



curl https://discoveryengine.googleapis.com/v1/{name=projects/${PROJECT_ID}/locations/${REGION}/dataStores}

curl https://discoveryengine.googleapis.com/v1/projects/${PROJECT_ID}/operations

echo '{"type": "OCR_PROCESSOR","displayName": "document-text-extraction"}' > request.json
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @request.json \
    "https://us-documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors"
