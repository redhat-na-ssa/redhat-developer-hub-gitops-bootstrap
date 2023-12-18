# Red Hat Developer Hub Gitops Cluster Bootstrap

This project repo contains a set of ArgoCD manifests and a set of Ansible Playbooks used to bootstrap a Developer Hub Environment on top of Openshift v4.x. The produced environment is intended for Developer workflows demo.

It uses the ArgoCD **App of Apps pattern** to pre-install and configure a set of Openshift Operators to support Developer Workflows.

The following components should be provisioned by ArgoCD in your cluster:
 * **Openshift Devspaces**
 * **Kubernetes Image Puller Operator**
 * **Git Webhook Operator**
 * **Hashicorp Vault**
 * **Vault Config Operator**
 * **Openshift Pipelines**
 * **Patch Operator**
 * **Cert Manager**
 * **...** (this list keeps growing as I need to add new components to my demos)

# First things first
If you got a "naked cluster" with just the `kubeadmin` system user. You can start by enabling the `htpasswd` auth provider and creating the `admin` user by using the `bootstrap-scripts/enable-htpasswd-users.sh`. 

This script will create the `admin` user as `cluster-admin` and 5 other regular (non-admin) users.

# Openshift GitOps installation and cluster bootstrap
You can choose to install **Openshift GitOps** Operator manually from the Operator Hub using the Openshift Console (Administrator Perspective) or you can

 1. Authenticate as a `cluster-admin` on your cluster and execute

```shell
 ./bootstrap-scripts/cluster-boostrap.sh 
```

This script will:
 * install Openshift GitOps (ArgoCD)
 * apply the ArgoCD root app
 * kickoff the cluster bootstrap
 
After applying this manifest go to the ArgoCD web console and watch the provisioning.
> **IMPORTANT**: It will take a while to have all components provisioned and in healthy state. The provisioning happens in "waves". You may have to refresh od sync come apps in case they remain in unhealthy state.

![ArgoCD Root App tree](./docs/images/ArgoCD-root-app-tree.png)

# Red Hat Developer Hub workflow (with Secret Management automation)

## Running Ansible Playbooks

If you don't have a Linux/MacOs box with access to your Openshift cluster you can create a Dev Workspace on Openshift DevSpaces and use it to change files and run the oc CLI and execute the Ansible playbooks in this sections. To do so go to the DevSpaces Dashboard and create a new workspace pointing to this repo. This repo contains a `devfile.yaml` ready for running Ansible.

**Remember to log in Openshift using `oc` CLI with a `cluster-admin` user before you run Ansible!!! ** When running the playbooks inside a DevSpaces workspace you may need to export `K8S_AUTH_CONTEXT=cluster-admin-context-name`, so Ansible can use the correct logged-in user to connect to Openshift. 

> Its recommended to create and use a Python virtual environment to properly run these playbooks (not needed if using DevSpaces workspace!)

 * To create a Python venv and install ansible and the dependencies we need run
  
```sh
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install ansible hvac kubernetes
source .venv/bin/activate
```

Before running the playbooks you need to setup a set of environment variables. 
To do so, create a hidden directory named `.ignored` (**this git repo is configured to ignore this directory on commit/push**). Then create a file named `env.sh` with the following content.

> **Note**: refer to [this guide](https://github.com/redhat-na-ssa/setup-playbooks/blob/main/rh-developer-hub/readme.md#create-github-organization-if-not-exist) to properly create a Github Organization and a App.
> Go to your Quay console and create a new organization and a Quay oAuth App. Then create a token with admin access to this org. 

```sh
export GITHUB_APP_APP_ID=
export GITHUB_APP_CLIENT_ID=
export GITHUB_APP_CLIENT_SECRET=
export GITHUB_APP_PRIVATE_KEY_FILE=.ignored/your-github-app.private-key.pem
export GITHUB_PRIVATE_KEY=$(< $GITHUB_APP_PRIVATE_KEY_FILE)
export GITHUB_ORG=
export GITHUB_ORG_URL=https://github.com/your-github-org-name
export GITHUB_APP_WEBHOOK_URL=https://developer-hub-rhdh.your-cluster-domain-here/
export GITHUB_APP_WEBHOOK_SECRET=rhdh-secret
export QUAY_ORG=your-quay-org-name
export QUAY_USER=a-quay-user-name
export QUAY_TOKEN=a-quay-oauth-app-token-with-admin-permissions
```

  * Source your env file before running Ansible.

```sa
source .ignored/env.sh
```

  * To configure our Vault Instance, run
```sh
ansible-playbook ansible-automation/playbooks/vault-setup/main.yaml
```

  * To install and configure Red Hat Developer Hub, run

```sh
ansible-playbook ansible-automation/playbooks/rhdh-install/main.yaml
```

At the end you should have all the infrastructure components represented in this diagram properly installed and configured. 

![DevHub Workflow](./docs/images/Red_Hat_DeveloperHub_Mgtm_Secrets_with_Hashicorp_Vault.png)

# Enabling Github oAuth provider (OPTIONAL!)
I use this repo to bootstrap an Openshift Cluster to showcase Openshift Dev Tooling and Developer workflows on top of Openshift Platform.
For this I like to integrate Openshift and Openshift DevSpaces with Github. 

To enable github users to authenticate on Openshift and DevSpaces using their Github accounts you need to configure Github oAuth. 

## Enabling Github users (developers) to access Openshift (OPTIONAL!)

 * Go to https://github.com/account/organizations/new?plan=free and create a new Github Personal Org"
 * Fill the fields with:
   * Organization Account Name: 'my-openshift-dev-team'
   * Contact email: 'your email address'
   * Check  'My personal account' for the Organization type

![](./docs/images/new-gb-personal-org.png)

> **IMPORTANT:** After creating your Personal Org, make sure you add members to it (including yourself)
> Go to https://github.com/orgs/your-org-name/people and invite/add members

![](./docs/images/gb-org-members.png)

 * Now go to https://github.com/settings/applications/new and create a new GitHub app
 * Fill the fields with:
   * Application Name: `Red Hat Openshift oAuth provider`
   * Homepage URL: `https://console-openshift-console.apps.cluster-domain.com/`
   * Authorization callback URL: `https://oauth-openshift.apps.cluster-domain.com/oauth2callback/github`

> **IMPORTANT:** <mark>Remember to copy the Client Id and the Client Secret values</mark>

![](./docs/images/new-gb-ocp-oauth-app.png)

## Configuring Github oAuth for DevSpaces (OPTIONAL!)

 * Now go to https://github.com/settings/applications/new and create another GitHub app (now for DevSpaces)
 * Fill the fields with:
   * Application Name: `Openshift DevSpaces oAuth provider`
   * Homepage URL: `https://devspaces.apps.cluster-domain.com/`
   * Authorization callback URL: `https://devspaces.apps.cluster-domain.com/api/oauth/callback`

> **IMPORTANT:** <mark>Remember to copy the Client Id and the Client Secret values</mark>

![](./docs/images/new-gb-devspaces-oauth-app.png)

## Applying the Github oAuth configuration to your Openshift cluster (OPTIONAL!)

With the Github Org and oAuth Apps properly created, now is time to apply the required configuration in your cluster. 

**To make things easy I created a script to guide you in this configuration. Just execute the `bootstrap-scripts/setup-github-oauth.sh` and follow the instructions.**

> **NOTE:** After you create the github secrets the Patch Operator will catch the secret `ocp-github-app-credentials` (should be present in the `openshift-config` namespaces) and automatically configure the Cluster oAuth resource for you. 

In a couple of seconds you should be able to access the cluster using Github as an Identity Provider.

![](./docs/images/gb-oauth-openshift-console.png)
