# gitlab-operator-kubernetes

# Overview

The GitLab operator is responsible for managing the full lifecycle of GitLab instances in your Kubernetes or Openshift container platforms.

[Documentation](https://docs.gitlab.com/charts/installation/operator.html)

The operator, while new and still actively being developed, aims to:
- ease installation and configuration of GitLab instances
- offer seamless upgrades from version to version

## GitLab

GitLab is a complete open-source DevOps platform, delivered as a single application, fundamentally changing the way Development, Security, and Ops teams collaborate and build software. From idea to production, GitLab helps teams improve cycle time from weeks to minutes, reduce development process costs and decrease time to market while increasing developer productivity.

Built on Open Source, GitLab delivers new innovations and features on the same day of every month by leveraging contributions from a passionate, global community of thousands of developers and millions of users. Over 100,000 of the world’s most demanding organizations trust GitLab to deliver great software at new speeds.

If you would like to enable advanced DevOps capabilities and activate enterprise features such as security, risk, and compliance capabilities, please contact our sales team to purchase an enterprise license.

# Prerequisites

Please visit [Prerequisites](https://docs.gitlab.com/charts/installation/operator.html#prerequisites) section of GitLab Operator Documentation.

## IngressClass

Cluster-wide `IngressClass` should be created prior to Operator setup, as OLM does not currently support this object type:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  # Ensure this value matches `spec.chart.values.global.ingress.class`
  # in the GitLab CR on the next step.
  name: gitlab-nginx
spec:
  controller: k8s.io/ingress-nginx
```
