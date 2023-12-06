#!/bin/bash
clear

SCRIPT_RELATIVE_DIR_PATH=$(dirname -- "${BASH_SOURCE}")
SCRATCH="${SCRIPT_RELATIVE_DIR_PATH}"/../scratch

mkdir -p "${SCRATCH}"
#echo " This script is located at: $( dirname -- "${BASH_SOURCE}" ) "
#echo " This script is located at: $( dirname -- "$(readlink -f "${BASH_SOURCE}")" ) "

# oc whoami
# [[ $? -gt 0 ]] && echo "💀 make sure you are logged in your Cluster with an cluster-admin user first! oc login..." && exit 1

create_htpasswd(){
  USERNAME=${1:-admin}
  PASSWORD=${2:-openshift}

  touch "${SCRATCH}"/htpasswd-users
  htpasswd -B -b "${SCRATCH}"/htpasswd-users "${USERNAME}" "${PASSWORD}"
}

echo
echo "creating admin and other 5 regular users..."
#switch to this if you wanna a random pwd for the admin user!
#readonly RANDOM_ADMIN_PWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 13 ; echo)

create_htpasswd admin
create_htpasswd user1 openshift
create_htpasswd user2 openshift
create_htpasswd user3 openshift
create_htpasswd user4 openshift
create_htpasswd user5 openshift

exit


oc delete secret htpasswd-secret --ignore-not-found=true -n openshift-config
oc create secret generic htpasswd-secret --from-file=htpasswd="${SCRIPT_RELATIVE_DIR_PATH}"/htpasswd-users -n openshift-config
oc replace -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpasswd-secret
EOF

oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm groups new cluster-admins admin
rm -f "${SCRIPT_RELATIVE_DIR_PATH}"/htpasswd-users

echo
echo "in a couple of minutes you should be able to login with admin user using [admin/$RANDOM_ADMIN_PWD] credentials!"
echo
#read -e -p "Do you want to remove the system 'kubeadmin' user? [Y/n]" typed_answer
#typed_answer=${typed_answer:-y}
#[[ $typed_answer == "y" ]] && echo "💀 deleting kubeadmin system user... Wait a couple of secs for the cluster oauth be ready, so you can authenticate with the new 'admin' user" && oc delete secret kubeadmin --ignore-not-found=true -n kube-system
