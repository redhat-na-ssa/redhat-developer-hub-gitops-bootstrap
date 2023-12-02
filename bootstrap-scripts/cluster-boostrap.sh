#!/bin/sh

# Define the retry function
#Blog post reference for this retry function: https://www.meziantou.net/retry-a-bash-command.htm
wait_and_retry() {
  local retries="$1"
  local wait="$2"
  local command="$3"

  # Run the command, and save the exit code
  $command
  local exit_code=$?

  # If the exit code is non-zero (i.e. command failed), and we have not
  # reached the maximum number of retries, run the command again
  if [[ $exit_code -ne 0 && $retries -gt 0 ]]; then
    # Wait before retrying
    echo "..."
    sleep $wait

    wait_and_retry $(($retries - 1)) $wait "$command"
  else
    # Return the exit code from the command
    return $exit_code
  fi
}

clear

readonly SCRIPT_RELATIVE_DIR_PATH=$(dirname -- "${BASH_SOURCE}")
#echo " This script is located at: $( dirname -- "${BASH_SOURCE}" ) "
#echo " This script is located at: $( dirname -- "$(readlink -f "${BASH_SOURCE}")" ) "

oc whoami
[[ $? -gt 0 ]] && echo "💀 make sure you are logged in your Cluster with an cluster-admin user first! oc login..." && exit 1

echo
echo "Install Openshift Gitops (ArgoCD) Operator"
oc apply -k $SCRIPT_RELATIVE_DIR_PATH/../components/operators/openshift-gitops-operator/operator/overlays/stable

echo
echo "wait until the Gitops operators is ready..."
#sleep 30

wait_and_retry 10 10 "oc wait pods -n openshift-operators -l control-plane=gitops-operator --for condition=Ready"

echo
echo "now create an argocd instance"
oc apply -k $SCRIPT_RELATIVE_DIR_PATH/../components/configs/kustomized/openshift-gitops-instance

echo
echo "wait (5s) until the ArgoCD instance is ready..."
# sleep 5
wait_and_retry 6 10 "oc get argocd -n openshift-gitops"

# echo
# echo "apply additional ClusterRoleBindings to ArgoCD Controller Service Accounts"
# oc apply -f $SCRIPT_RELATIVE_DIR_PATH/../openshift-gitops-install/rbac.yaml

echo
echo "bootstrapping the components though Openshift GitOps (ArgoCD)..."
oc apply -k $SCRIPT_RELATIVE_DIR_PATH/../components/argocd/apps/overlays/dev-hub-demo

argocdurl=$(oc get route openshift-gitops-server --ignore-not-found=true -n "openshift-gitops" -o jsonpath="{'https://'}{.status.ingress[0].host}")
echo
echo "you can now access Openshift Gitops though: $argocdurl"