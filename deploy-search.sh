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
# Important: Specify the metadata bucket in the gcsSource config, NOT the bucket with the source pdf's. The metadata in the jsonl files will point to the associated pdf. 
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://discoveryengine.googleapis.com/v1/projects/${PROJECT_ID}/locations/global/collections/default_collection/dataStores/${DATA_STORE_ID}/branches/0/documents:import" \
  -d '{
    "gcsSource": {
      "inputUris": ["gs://'${DOCS_METADATA_BUCKET}'/*.jsonl"],
      "dataSchema": "document",
    }
  }'

# Create S&C App
# Ref: https://cloud.google.com/generative-ai-app-builder/docs/create-engine-es
# Note: Faceted search for the widget has to be enabled manually in the console as of today.
curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
-H "X-Goog-User-Project: ${PROJECT_ID}" \
"https://discoveryengine.googleapis.com/v1/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines?engineId=search-prospectus-${PROJECT_ID}" \
-d '{
  "displayName": "search-prospectus",
  "dataStoreIds": ["'${DATA_STORE_ID}'"],
  "solutionType": "SOLUTION_TYPE_SEARCH",
  "searchEngineConfig": {
     "searchTier": "SEARCH_TIER_ENTERPRISE",
     "searchAddOns": ["SEARCH_ADD_ON_LLM"]
   }
}'