#!/bin/bash
# Run this script from the main folder to deploy the project to Azure
echo ">>> Copy IdentityHub and RegistrationService CLI JARs <<<"
./gradlew getJarsForLocalTest getJarsForAzureTest

echo ">>> Build runtimes <<<"
./gradlew shadowJar
###
echo ">>> Cd to setup_azure_ad <<<"
cd resources/setup_azure_ad
###
echo ">>> Initializing Azure Dataspace - Terraform <<<"
terraform init
terraform apply
source env-vars
###
echo ">>> Github Actions: Creating Azure Dataspace <<<"
./set-gh-secrets.sh
cd ../../
gh workflow run .github/workflows/initialize.yaml
sleep 1m 30s
###
echo ">>> Cd to deployment/azure <<<"
cd deployment/azure
###
echo ">>> Creating Azure Dataspace Resources <<<"
./create_azure_dataspace.sh
az storage blob upload --overwrite -c $TERRAFORM_STATE_CONTAINER --account-name $TERRAFORM_STATE_STORAGE_ACCOUNT -f terraform/terraform.tfvars -n terraform.tfvars
###
echo ">>> Creating Azure Dataspace Local Runtimes <<<"
docker compose -f docker/docker-compose.yml --profile ui up --build --wait
###
echo ">>> Seeding Dataspace <<<"
./seed_dataspace.sh