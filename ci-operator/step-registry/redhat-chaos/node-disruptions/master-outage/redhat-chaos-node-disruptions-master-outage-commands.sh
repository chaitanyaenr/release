#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -x
cat /etc/os-release
oc config view
oc projects
python3 --version


ES_PASSWORD=$(cat "/secret/es/password")
ES_USERNAME=$(cat "/secret/es/username")


export ES_SERVER="https://$ES_USERNAME:$ES_PASSWORD@search-ocp-qe-perf-scale-test-elk-hcm7wtsqpxy7xogbu72bor4uve.us-east-1.es.amazonaws.com"
export ELASTIC_INDEX=krkn_chaos_ci


echo "kubeconfig loc $$KUBECONFIG"
echo "Using the flattened version of kubeconfig"
oc config view --flatten > /tmp/config
export KUBECONFIG=/tmp/config
export KRKN_KUBE_CONFIG=$KUBECONFIG
envsubst < /home/krkn/kraken/scenarios/plugin_node_scenario.yaml.template > /home/krkn/kraken/scenarios/node_scenario.yaml
export SCENARIO_TYPE="plugin_scenarios"
export ACTION=${ACTION:="$CLOUD_TYPE-node-reboot"}

if [[ "$CLOUD_TYPE" == "aws" ]]; then
  mkdir -p $HOME/.aws
  cat "/secret/telemetry/.awscred" > $HOME/.aws/config
  cat ${CLUSTER_PROFILE_DIR}/.awscred > $HOME/.aws/config
  export AWS_DEFAULT_REGION=us-west-2
elif [[ "$CLOUD_TYPE" == "azure" ]]; then
  azure_tenant_id=$( cat "/secret/telemetry/azure_tenant_id")
  azure_client_secret=$(cat "/secret/telemetry/azure_client_secret")
  azure_client_id=$(cat "/secret/telemetry/azure_client_id")
  export AZURE_TENANT_ID=$azure_tenant_id
  export AZURE_CLIENT_SECRET=$azure_client_secret
  export AZURE_CLIENT_ID=$azure_client_id
else
  echo "$CLOUD_TYPE is not supported, please check"
fi 

# read and export passwords from vault
telemetry_password=$(cat "/secret/telemetry/telemetry_password")
export TELEMETRY_PASSWORD=$telemetry_password

ls node-disruptions

./node-disruptions/prow_run.sh
rc=$?
echo "Finished running node disruptions"
echo "Return code: $rc"
