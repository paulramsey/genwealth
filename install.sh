###
### Deploys the genwealth app 
###
### NOTE: you need the latest version of gcloud (i.e. 468 or later) to deploy this
###

# Deploy each layer of the stack
echo "Deploying the back end."
source ./deploy-backend.sh
echo "Deploying the document ingestion pipeline."
source ./deploy-pipeline.sh
echo "Deploying Vertex AI Search and Conversation."
source ./deploy-search.sh
echo "Deploying front end dependencies."
source ./deploy-registry.sh
echo "Deploying the front end."
source ./deploy-frontend.sh
echo "Install complete."
