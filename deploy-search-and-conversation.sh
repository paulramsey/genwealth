# Load env variables
source ./env.sh

# Enable discoveryengine.googleapis.com
gcloud services enable discoveryengine.googleapis.com --project ${PROJECT_ID}



curl https://discoveryengine.googleapis.com/v1/{name=projects/${PROJECT_ID}/locations/${REGION}/dataStores}

curl https://discoveryengine.googleapis.com/v1/projects/${PROJECT_ID}/operations

echo '{"type": "OCR_PROCESSOR","displayName": "document-text-extraction"}' > request.json
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @request.json \
    "https://us-documentai.googleapis.com/v1/projects/${PROJECT_ID}/locations/us/processors"
