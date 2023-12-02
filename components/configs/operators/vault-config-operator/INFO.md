# vault-config-operator

This operator helps set up Vault Configurations. The main intent is to do so such that subsequently pods can consume the secrets made available.
There are two main principles through all of the capabilities of this operator:

1. high-fidelity API. The CRD exposed by this operator reflect field by field the Vault APIs. This is because we don't want to make any assumption on the kinds of configuration workflow that user will set up. That being said the Vault API is very extensive and we are starting with enough API coverage to support, we think, some simple and very common configuration workflows.
2. attention to security (after all we are integrating with a security tool). To prevent credential leaks we give no permissions to the operator itself against Vault. All APIs exposed by this operator contains enough information to authenticate to Vault using a local service account (local to the namespace where the API exist). In other word for a namespace user to be abel to successfully configure Vault, a service account in that namespace must have been previously given the needed Vault permissions.

Currently this operator supports the following CRDs:

1. [Policy](https://github.com/redhat-cop/vault-config-operator#policy) Configures Vault [Policies](https://www.vaultproject.io/docs/concepts/policies)
2. [KubernetesAuthEngineRole](https://github.com/redhat-cop/vault-config-operator#KubernetesAuthEngineRole) Configures a Vault [Kubernetes Authentication](https://www.vaultproject.io/docs/auth/kubernetes) Role
3. [SecretEngineMount](https://github.com/redhat-cop/vault-config-operator#SecretEngineMount) Configures a Mount point for a [SecretEngine](https://www.vaultproject.io/docs/secrets)
4. [DatabaseSecretEngineConfig](https://github.com/redhat-cop/vault-config-operator#DatabaseSecretEngineConfig) Configures a [Database Secret Engine](https://www.vaultproject.io/docs/secrets/databases) Connection
5. [DatabaseSecretEngineRole](https://github.com/redhat-cop/vault-config-operator#DatabaseSecretEngineRole) Configures a [Database Secret Engine](https://www.vaultproject.io/docs/secrets/databases) Role
6. [RandomSecret](https://github.com/redhat-cop/vault-config-operator#RandomSecret) Creates a random secret in a vault [kv Secret Engine](https://www.vaultproject.io/docs/secrets/kv) with one password field generated using a [PasswordPolicy](https://www.vaultproject.io/docs/concepts/password-policies)vault-config-operator
