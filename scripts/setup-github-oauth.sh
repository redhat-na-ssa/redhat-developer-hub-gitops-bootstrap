#!/bin/bash

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly ORANGE='\033[38;5;214m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

clear
echo
# for OCP
echo -e "${BOLD}${GREEN}Go to https://github.com/account/organizations/new?plan=free and create a new Github Personal Org.${NC} "
echo -e "\n\tFill the fields with:${NC}"
echo -e "\tOrganization Account Name: 'my-openshift-dev-team'${NC}"
echo -e "\tContact email: 'your email address'${NC}"
echo -e "\tCheck  'My personal account' for the Organization type${NC}"
echo
echo -e "${BOLD}${ORANGE}>>> After creating your Personal Org, make sure you add members to it (including yourself) <<<${NC}"
read -e -p "hit Enter to continue. "
echo
read -e -p "$(echo -e ${GREEN}">> Organization name you wanna to give cluster access to: "${NC})" orgName
[[ -z $orgName ]] && echo -e "💀 ${RED}GitHub Organization names (comma separated) required! Restart this script and try again.${NC}\n" && exit 1

echo
echo -e "${BOLD}${GREEN}Now go to https://github.com/settings/applications/new and create a new GitHub app.${NC}"
echo -e "\n\tFill the fields with:${NC}"
echo -e "\tApplication Name: 'Red Hat Openshift oAuth provider'${NC}"
echo -e "\tHomepage URL: 'https://console-openshift-console.apps.cluster-domain/'${NC}"
echo -e "\tAuthorization callback URL: 'https://oauth-openshift.apps.cluster-domain/oauth2callback/github'${NC}"
echo
echo -e "${BOLD}${ORANGE}>>> Remember to copy the Client Id and the Client Secret values <<<${NC}"
read -e -p "hit Enter to continue. "

echo
read -e -p "$(echo -e ${GREEN}">> paste the Github app Client Id: "${NC})" clientId
read -e -p "$(echo -e ${GREEN}">> paste the Github app Client Secret: "${NC})" clientSecret
echo
[[ -z $clientId ]] && echo -e "💀 ${RED}GitHub app Client Id required! Restart this script and try again.${NC}\n" && exit 1
[[ -z $clientSecret ]] && echo -e "💀 ${RED}GitHub app Client Secret required! Restart this script and try again.${NC}\n" && exit 1

oc delete secret ocp-github-app-credentials --ignore-not-found=true -n openshift-config
oc create secret generic ocp-github-app-credentials -n openshift-config \
--from-literal=client_id=${clientId} \
--from-literal=clientSecret=${clientSecret} \
--from-literal=orgs=${orgName}

echo
echo "---"

#for DevSpaces
echo
echo -e "${BOLD}${GREEN}Now go to https://github.com/settings/applications/new and create another GitHub app (now for DevSpaces).${NC}"
echo -e "\n\tFill the fields with:${NC}"
echo -e "\tApplication Name: 'Openshift DevSpaces oAuth provider'${NC}"
echo -e "\tHomepage URL: 'https://devspaces.apps.cluster-domain/'${NC}"
echo -e "\tAuthorization callback URL: 'https://devspaces.apps.cluster-domain/api/oauth/callback'${NC}"
echo -e "${BOLD}${ORANGE}>>> Remember to copy the Client Id and the Client Secret values <<<${NC}"
read -e -p "hit Enter to continue. "

echo
unset clientId
unset clientSecret
read -e -p "$(echo -e ${GREEN}">> paste the Github app Client Id: "${NC})" clientId
read -e -p "$(echo -e ${GREEN}">> paste the Github app Client Secret: "${NC})" clientSecret
echo
[[ -z $clientId ]] && echo -e "💀 ${RED}GitHub app Client Id required! Restart this script and try again.${NC}\n" && exit 1
[[ -z $clientSecret ]] && echo -e "💀 ${RED}GitHub app Client Secret required! Restart this script and try again.${NC}\n" && exit 1

oc delete secret github-oauth-config --ignore-not-found=true -n openshift-devspaces
oc create secret generic github-oauth-config -n openshift-devspaces \
--from-literal=id=$clientId \
--from-literal=secret=$clientSecret

oc label secret github-oauth-config -n openshift-devspaces \
--overwrite=true app.kubernetes.io/part-of=che.eclipse.org app.kubernetes.io/component=oauth-scm-configuration
oc annotate secret github-oauth-config -n openshift-devspaces \
--overwrite=true che.eclipse.org/oauth-scm-server=github