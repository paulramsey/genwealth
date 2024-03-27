# Set project id
PROJECT_ID=$(gcloud config get-value project 2> /dev/null)

# Prompt user for AlloyDB password
read -s -p "Enter a password for the AlloyDB cluster: " ALLOYDB_PASSWORD

# Create AlloyDB password secret
gcloud secrets create alloydb-password-${PROJECT_ID} \
    --replication-policy="automatic"

echo -n "$ALLOYDB_PASSWORD" | \
    gcloud secrets versions add alloydb-password-${PROJECT_ID} --data-file=-

# Prompt user for pgAdmin password
read -s -p "Enter a password for pgAdmin: " PGADMIN_PASSWORD

# Create database password secret
gcloud secrets create pgadmin-password-${PROJECT_ID} \
    --replication-policy="automatic"

echo -n "$PGADMIN_PASSWORD" | \
    gcloud secrets versions add pgadmin-password-${PROJECT_ID} --data-file=-
