# Load env variables
source ./env.sh

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
