###
### Deploys the genwealth app to Cloud Run
###
### NOTE: you need the latest version of gcloud (i.e. 468 or later) to deploy this
###

# Load env variables
source ./env.sh

PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
  echo "PROJECT_ID is not set."
  exit 1
fi


if [ -z "$REGION" ]; then
  REGION=$(gcloud config get-value run/region)
  if [ -z "$REGION" ]; then
    echo "REGION is not set. Please set the gcloud run/region."
    exit 1
  fi
fi

# Update org policies
echo "Updating org policies"
declare -a policies=("constraints/run.allowedIngress"
                "constraints/iam.allowedPolicyMemberDomains"
                )
for policy in "${policies[@]}"
do
cat <<EOF > new_policy.yaml
constraint: $policy
listPolicy:
 allValues: ALLOW
EOF
gcloud resource-manager org-policies set-policy new_policy.yaml --project=$PROJECT_ID
done

echo "Waiting 60 seconds for org policies to take effect"
sleep 60


#
# Create the Artifact Registry repository:
#
echo "Creating the Artifact Registry repository"
gcloud artifacts repositories create genwealth \
--repository-format=docker \
--location=$REGION \
--project=$PROJECT_ID 

#
# Build & push the container
#
echo "Deploying the front end."
source ./deploy-frontend.sh
