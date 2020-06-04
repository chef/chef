#!/usr/bin/env bash

set -euo pipefail

echo "--- Setting up Azure credentials"
export VAULT_UTIL_SECRETS="{\"ARM_TENANT_ID\":{\"account\":\"azure/engineering-dev-test\",\"field\":\"tenant_id\"},\"ARM_CLIENT_ID\":{\"account\":\"azure/engineering-dev-test\",\"field\":\"client_id\"},\"ARM_CLIENT_SECRET\":{\"account\":\"azure/engineering-dev-test\",\"field\":\"client_secret\"}}"
. <(vault-util fetch-secret-env)

# this allows time for the new service-principal to become available
sleep 10

az login --service-principal --tenant "$ARM_TENANT_ID" --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"

echo "--- Deleting Azure kitchen-end-to-end-windows-10 resource groups"
az group list --query "[?starts_with(name, 'kitchen-end-to-end-windows-10-')].name" --output tsv | xargs -n1 -t -I% az group delete -y --no-wait --name "%"
