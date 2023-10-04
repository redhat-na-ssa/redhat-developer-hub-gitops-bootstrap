#!/bin/sh
clear

readonly SCRIPT_RELATIVE_DIR_PATH=$(dirname -- "${BASH_SOURCE}")
#echo " This script is located at: $( dirname -- "${BASH_SOURCE}" ) "
#echo " This script is located at: $( dirname -- "$(readlink -f "${BASH_SOURCE}")" ) "

oc whoami
[[ $? -gt 0 ]] && echo "💀 make sure you are logged in your Cluster with an cluster-admin user first! oc login..." && exit 1

echo
echo "creating admin and other 5 regular users..."
#switch to this if you wanna a random pwd for the admin user!
#readonly RANDOM_ADMIN_PWD=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 13 ; echo)
readonly RANDOM_ADMIN_PWD=openshift
htpasswd -B -b -c ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users admin $RANDOM_ADMIN_PWD
htpasswd -B -b ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users user1 openshift
htpasswd -B -b ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users user2 openshift
htpasswd -B -b ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users user3 openshift
htpasswd -B -b ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users user4 openshift
htpasswd -B -b ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users user5 openshift

oc delete secret htpasswd-secret --ignore-not-found=true -n openshift-config
oc create secret generic htpasswd-secret --from-file=htpasswd=${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users -n openshift-config
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
rm -f ${SCRIPT_RELATIVE_DIR_PATH}/htpasswd-users

echo
echo "in a couple of minutes you should be able to login with admin user using [admin/$RANDOM_ADMIN_PWD] credentials!"
echo
#read -e -p "Do you want to remove the system 'kubeadmin' user? [Y/n]" typed_answer
#typed_answer=${typed_answer:-y}
#[[ $typed_answer == "y" ]] && echo "💀 deleting kubeadmin system user... Wait a couple of secs for the cluster oauth be ready, so you can authenticate with the new 'admin' user" && oc delete secret kubeadmin --ignore-not-found=true -n kube-system
