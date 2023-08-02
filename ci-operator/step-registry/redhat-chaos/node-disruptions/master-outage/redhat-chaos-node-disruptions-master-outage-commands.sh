#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -x
cat /etc/os-release
oc config view
oc projects
python3 --version
pushd /tmp

#ls -la /root/kraken
#python3.9 -m virtualenv ./chaos
#source ./chaos/bin/activate
#pip3.9 install -r /root/kraken/requirements.txt
git clone https://github.com/redhat-chaos/krkn-hub.git
pushd krkn-hub/

echo "kubeconfig loc $$KUBECONFIG"
echo "Using the flattened version of kubeconfig"
oc config view --flatten > /tmp/config
export KUBECONFIG=/tmp/config

export KRKN_KUBE_CONFIG=$KUBECONFIG
export NAMESPACE=$TARGET_NAMESPACE

chmod +x ./prow/node-disruptions/prow_run.sh
./prow/node-disruptions/prow_run.sh
rc=$?
echo "Finished running node disruptions"
echo "Return code: $rc"
