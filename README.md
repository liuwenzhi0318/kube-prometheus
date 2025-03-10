# kube-prometheus

[![Build Status](https://github.com/prometheus-operator/kube-prometheus/workflows/ci/badge.svg)](https://github.com/prometheus-operator/kube-prometheus/actions)
[![Slack](https://img.shields.io/badge/join%20slack-%23prometheus--operator-brightgreen.svg)](http://slack.k8s.io/)
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/prometheus-operator/kube-prometheus)

> Note that everything is experimental and may change significantly at any time.

This repository collects Kubernetes manifests, [Grafana](http://grafana.com/) dashboards, and [Prometheus rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with [Prometheus](https://prometheus.io/) using the Prometheus Operator.

The content of this project is written in [jsonnet](http://jsonnet.org/). This project could both be described as a package as well as a library.

Components included in this package:

* The [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
* Highly available [Prometheus](https://prometheus.io/)
* Highly available [Alertmanager](https://github.com/prometheus/alertmanager)
* [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
* [Prometheus Adapter for Kubernetes Metrics APIs](https://github.com/DirectXMan12/k8s-prometheus-adapter)
* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
* [Grafana](https://grafana.com/)

This stack is meant for cluster monitoring, so it is pre-configured to collect metrics from all Kubernetes components. In addition to that it delivers a default set of dashboards and alerting rules. Many of the useful dashboards and alerts come from the [kubernetes-mixin project](https://github.com/kubernetes-monitoring/kubernetes-mixin), similar to this project it provides composable jsonnet as a library for users to customize to their needs.

## Warning

If you are migrating from `release-0.7` branch or earlier please read [what changed and how to migrate in our guide](https://github.com/prometheus-operator/kube-prometheus/blob/main/docs/migration-guide.md).

## Table of contents

- [kube-prometheus](#kube-prometheus)
  - [Warning](#warning)
  - [Table of contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
    - [minikube](#minikube)
  - [Compatibility](#compatibility)
    - [Kubernetes compatibility matrix](#kubernetes-compatibility-matrix)
  - [Quickstart](#quickstart)
    - [Access the dashboards](#access-the-dashboards)
  - [Customizing Kube-Prometheus](#customizing-kube-prometheus)
    - [Installing](#installing)
    - [Compiling](#compiling)
    - [Apply the kube-prometheus stack](#apply-the-kube-prometheus-stack)
    - [Containerized Installing and Compiling](#containerized-installing-and-compiling)
  - [Update from upstream project](#update-from-upstream-project)
    - [Update jb](#update-jb)
    - [Update kube-prometheus](#update-kube-prometheus)
    - [Compile the manifests and apply](#compile-the-manifests-and-apply)
  - [Configuration](#configuration)
  - [Customization Examples](#customization-examples)
    - [Cluster Creation Tools](#cluster-creation-tools)
    - [Internal Registry](#internal-registry)
    - [NodePorts](#nodeports)
    - [Prometheus Object Name](#prometheus-object-name)
    - [node-exporter DaemonSet namespace](#node-exporter-daemonset-namespace)
    - [Alertmanager configuration](#alertmanager-configuration)
    - [Adding additional namespaces to monitor](#adding-additional-namespaces-to-monitor)
      - [Defining the ServiceMonitor for each additional Namespace](#defining-the-servicemonitor-for-each-additional-namespace)
    - [Monitoring all namespaces](#monitoring-all-namespaces)
    - [Static etcd configuration](#static-etcd-configuration)
    - [Pod Anti-Affinity](#pod-anti-affinity)
    - [Stripping container resource limits](#stripping-container-resource-limits)
    - [Customizing Prometheus alerting/recording rules and Grafana dashboards](#customizing-prometheus-alertingrecording-rules-and-grafana-dashboards)
    - [Exposing Prometheus/Alermanager/Grafana via Ingress](#exposing-prometheusalermanagergrafana-via-ingress)
    - [Setting up a blackbox exporter](#setting-up-a-blackbox-exporter)
  - [Minikube Example](#minikube-example)
  - [Continuous Delivery](#continuous-delivery)
  - [Troubleshooting](#troubleshooting)
    - [Error retrieving kubelet metrics](#error-retrieving-kubelet-metrics)
      - [Authentication problem](#authentication-problem)
      - [Authorization problem](#authorization-problem)
    - [kube-state-metrics resource usage](#kube-state-metrics-resource-usage)
    - [Error retrieving kube-proxy metrics](#error-retrieving-kube-proxy-metrics)
  - [Contributing](#contributing)
  - [License](#license)

## Prerequisites

You will need a Kubernetes cluster, that's it! By default it is assumed, that the kubelet uses token authentication and authorization, as otherwise Prometheus needs a client certificate, which gives it full access to the kubelet, rather than just the metrics. Token authentication and authorization allows more fine grained and easier access control.

This means the kubelet configuration must contain these flags:

* `--authentication-token-webhook=true` This flag enables, that a `ServiceAccount` token can be used to authenticate against the kubelet(s). This can also be enabled by setting the kubelet configuration value `authentication.webhook.enabled` to `true`.
* `--authorization-mode=Webhook` This flag enables, that the kubelet will perform an RBAC request with the API to determine, whether the requesting entity (Prometheus in this case) is allowed to access a resource, in specific for this project the `/metrics` endpoint. This can also be enabled by setting the kubelet configuration value `authorization.mode` to `Webhook`.

This stack provides [resource metrics](https://github.com/kubernetes/metrics#resource-metrics-api) by deploying the [Prometheus Adapter](https://github.com/DirectXMan12/k8s-prometheus-adapter/).
This adapter is an Extension API Server and Kubernetes needs to be have this feature enabled, otherwise the adapter has no effect, but is still deployed.

### minikube

To try out this stack, start [minikube](https://github.com/kubernetes/minikube) with the following command:

```shell
$ minikube delete && minikube start --kubernetes-version=v1.20.0 --memory=6g --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.address=0.0.0.0 --extra-config=controller-manager.address=0.0.0.0
```

The kube-prometheus stack includes a resource metrics API server, so the metrics-server addon is not necessary. Ensure the metrics-server addon is disabled on minikube:

```shell
$ minikube addons disable metrics-server
```

## Compatibility

### Kubernetes compatibility matrix

The following versions are supported and work as we test against these versions in their respective branches. But note that other versions might work!

| kube-prometheus stack                                                                    | Kubernetes 1.18 | Kubernetes 1.19 | Kubernetes 1.20 | Kubernetes 1.21 | Kubernetes 1.22 |
|------------------------------------------------------------------------------------------|-----------------|-----------------|-----------------|-----------------|-----------------|
| [`release-0.6`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.6) | ✗               | ✔               | ✗               | ✗               | ✗               |
| [`release-0.7`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.7) | ✗               | ✔               | ✔               | ✗               | ✗               |
| [`release-0.8`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.8) | ✗               | ✗               | ✔               | ✔               | ✗               |
| [`release-0.9`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.9) | ✗               | ✗               | ✗               | ✔               | ✔               |
| [`HEAD`](https://github.com/prometheus-operator/kube-prometheus/tree/main)               | ✗               | ✗               | ✗               | ✔               | ✔               |

## Quickstart

> Note: For versions before Kubernetes v1.21.z refer to the [Kubernetes compatibility matrix](#kubernetes-compatibility-matrix) in order to choose a compatible branch.

This project is intended to be used as a library (i.e. the intent is not for you to create your own modified copy of this repository).

Though for a quickstart a compiled version of the Kubernetes [manifests](manifests) generated with this library (specifically with `example.jsonnet`) is checked into this repository in order to try the content out quickly. To try out the stack un-customized run:
* Create the monitoring stack using the config in the `manifests` directory:

```shell
# Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/
```

We create the namespace and CustomResourceDefinitions first to avoid race conditions when deploying the monitoring components.
Alternatively, the resources in both folders can be applied with a single command
`kubectl create -f manifests/setup -f manifests`, but it may be necessary to run the command multiple times for all components to
be created successfullly.

* And to teardown the stack:

```shell
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
```

### Access the dashboards

Prometheus, Grafana, and Alertmanager dashboards can be accessed quickly using `kubectl port-forward` after running the quickstart via the commands below. Kubernetes 1.10 or later is required.

> Note: There are instructions on how to route to these pods behind an ingress controller in the [Exposing Prometheus/Alermanager/Grafana via Ingress](#exposing-prometheusalermanagergrafana-via-ingress) section.

Prometheus

```shell
$ kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
```

Then access via [http://localhost:9090](http://localhost:9090)

Grafana

```shell
$ kubectl --namespace monitoring port-forward svc/grafana 3000
```

Then access via [http://localhost:3000](http://localhost:3000) and use the default grafana user:password of `admin:admin`.

Alert Manager

```shell
$ kubectl --namespace monitoring port-forward svc/alertmanager-main 9093
```

Then access via [http://localhost:9093](http://localhost:9093)

## Customizing Kube-Prometheus

This section:
* describes how to customize the kube-prometheus library via compiling the kube-prometheus manifests yourself (as an alternative to the [Quickstart section](#quickstart)).
* still doesn't require you to make a copy of this entire repository, but rather only a copy of a few select files.

### Installing

The content of this project consists of a set of [jsonnet](http://jsonnet.org/) files making up a library to be consumed.

Install this library in your own project with [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler#install) (the jsonnet package manager):

```shell
$ mkdir my-kube-prometheus; cd my-kube-prometheus
$ jb init  # Creates the initial/empty `jsonnetfile.json`
# Install the kube-prometheus dependency
$ jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.9 # Creates `vendor/` & `jsonnetfile.lock.json`, and fills in `jsonnetfile.json`

$ wget https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/release-0.9/example.jsonnet -O example.jsonnet
$ wget https://raw.githubusercontent.com/prometheus-operator/kube-prometheus/release-0.9/build.sh -O build.sh
```

> `jb` can be installed with `go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb`

> An e.g. of how to install a given version of this library: `jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.9`

In order to update the kube-prometheus dependency, simply use the jsonnet-bundler update functionality:

```shell
$ jb update
```

### Compiling

e.g. of how to compile the manifests: `./build.sh example.jsonnet`

> before compiling, install `gojsontoyaml` tool with `go get github.com/brancz/gojsontoyaml` and `jsonnet` with `go get github.com/google/go-jsonnet/cmd/jsonnet`

Here's [example.jsonnet](example.jsonnet):

> Note: some of the following components must be configured beforehand. See [configuration](#configuration) and [customization-examples](#customization-examples).

```jsonnet mdox-exec="cat example.jsonnet"
local kp =
  (import 'kube-prometheus/main.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'monitoring',
      },
    },
  };

{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
```

And here's the [build.sh](build.sh) script (which uses `vendor/` to render all manifests in a json structure of `{filename: manifest-content}`):

```sh mdox-exec="cat build.sh"
#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests "${1-example.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization

```

> Note you need `jsonnet` (`go get github.com/google/go-jsonnet/cmd/jsonnet`) and `gojsontoyaml` (`go get github.com/brancz/gojsontoyaml`) installed to run `build.sh`. If you just want json output, not yaml, then you can skip the pipe and everything afterwards.

This script runs the jsonnet code, then reads each key of the generated json and uses that as the file name, and writes the value of that key to that file, and converts each json manifest to yaml.

### Apply the kube-prometheus stack

The previous steps (compilation) has created a bunch of manifest files in the manifest/ folder.
Now simply use `kubectl` to install Prometheus and Grafana as per your configuration:

```shell
# Update the namespace and CRDs, and then wait for them to be available before creating the remaining resources
$ kubectl apply -f manifests/setup
$ kubectl apply -f manifests/
```

Alternatively, the resources in both folders can be applied with a single command
`kubectl apply -Rf manifests`, but it may be necessary to run the command multiple times for all components to
be created successfullly.

Check the monitoring namespace (or the namespace you have specific in `namespace: `) and make sure the pods are running. Prometheus and Grafana should be up and running soon.

### Containerized Installing and Compiling

If you don't care to have `jb` nor `jsonnet` nor `gojsontoyaml` installed, then use `quay.io/coreos/jsonnet-ci` container image. Do the following from this `kube-prometheus` directory:

```shell
$ docker run --rm -v $(pwd):$(pwd) --workdir $(pwd) quay.io/coreos/jsonnet-ci jb update
$ docker run --rm -v $(pwd):$(pwd) --workdir $(pwd) quay.io/coreos/jsonnet-ci ./build.sh example.jsonnet
```

## Update from upstream project

You may wish to fetch changes made on this project so they are available to you.

### Update jb

`jb` may have been updated so it's a good idea to get the latest version of this binary:

```shell
$ go get -u github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
```

### Update kube-prometheus

The command below will sync with upstream project:

```shell
$ jb update
```

### Compile the manifests and apply

Once updated, just follow the instructions under "Compiling" and "Apply the kube-prometheus stack" to apply the changes to your cluster.

## Configuration

Jsonnet has the concept of hidden fields. These are fields, that are not going to be rendered in a result. This is used to configure the kube-prometheus components in jsonnet. In the example jsonnet code of the above [Customizing Kube-Prometheus section](#customizing-kube-prometheus), you can see an example of this, where the `namespace` is being configured to be `monitoring`. In order to not override the whole object, use the `+::` construct of jsonnet, to merge objects, this way you can override individual settings, but retain all other settings and defaults.

The available fields and their default values can be seen in [main.libsonnet](jsonnet/kube-prometheus/main.libsonnet). Note that many of the fields get their default values from variables, and for example the version numbers are imported from [versions.json](jsonnet/kube-prometheus/versions.json).

Configuration is mainly done in the `values` map. You can see this being used in the `example.jsonnet` to set the namespace to `monitoring`. This is done in the `common` field, which all other components take their default value from. See for example how Alertmanager is configured in `main.libsonnet`:

```
    alertmanager: {
      name: 'main',
      // Use the namespace specified under values.common by default.
      namespace: $.values.common.namespace,
      version: $.values.common.versions.alertmanager,
      image: $.values.common.images.alertmanager,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
```

The grafana definition is located in a different project (https://github.com/brancz/kubernetes-grafana ), but needed configuration can be customized from the same top level `values` field. For example to allow anonymous access to grafana, add the following `values` section:

```
      grafana+:: {
        config: { // http://docs.grafana.org/installation/configuration/
          sections: {
            "auth.anonymous": {enabled: true},
          },
        },
      },
```

## Customization Examples

Jsonnet is a turing complete language, any logic can be reflected in it. It also has powerful merge functionalities, allowing sophisticated customizations of any kind simply by merging it into the object the library provides.

### Cluster Creation Tools

A common example is that not all Kubernetes clusters are created exactly the same way, meaning the configuration to monitor them may be slightly different. For the following clusters there are mixins available to easily configure them:

* aws
* bootkube
* eks
* gke
* kops
* kops_coredns
* kubeadm
* kubespray

These mixins are selectable via the `platform` field of kubePrometheus:

```jsonnet mdox-exec="cat examples/jsonnet-snippets/platform.jsonnet"
(import 'kube-prometheus/main.libsonnet') +
{
  values+:: {
    common+: {
      platform: 'example-platform',
    },
  },
}
```

### Internal Registry

Some Kubernetes installations source all their images from an internal registry. kube-prometheus supports this use case and helps the user synchronize every image it uses to the internal registry and generate manifests pointing at the internal registry.

To produce the `docker pull/tag/push` commands that will synchronize upstream images to `internal-registry.com/organization` (after having run the `jb` command to populate the vendor directory):

```shell
$ jsonnet -J vendor -S --tla-str repository=internal-registry.com/organization sync-to-internal-registry.jsonnet
$ docker pull k8s.gcr.io/addon-resizer:1.8.4
$ docker tag k8s.gcr.io/addon-resizer:1.8.4 internal-registry.com/organization/addon-resizer:1.8.4
$ docker push internal-registry.com/organization/addon-resizer:1.8.4
$ docker pull quay.io/prometheus/alertmanager:v0.16.2
$ docker tag quay.io/prometheus/alertmanager:v0.16.2 internal-registry.com/organization/alertmanager:v0.16.2
$ docker push internal-registry.com/organization/alertmanager:v0.16.2
...
```

The output of this command can be piped to a shell to be executed by appending `| sh`.

Then to generate manifests with `internal-registry.com/organization`, use the `withImageRepository` mixin:

```jsonnet mdox-exec="cat examples/internal-registry.jsonnet"
local mixin = import 'kube-prometheus/addons/config-mixins.libsonnet';
local kp = (import 'kube-prometheus/main.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
  },
} + mixin.withImageRepository('internal-registry.com/organization');

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

### NodePorts

Another mixin that may be useful for exploring the stack is to expose the UIs of Prometheus, Alertmanager and Grafana on NodePorts:

```jsonnet mdox-exec="cat examples/jsonnet-snippets/node-ports.jsonnet"
(import 'kube-prometheus/main.libsonnet') +
(import 'kube-prometheus/addons/node-ports.libsonnet')
```

### Prometheus Object Name

To give another customization example, the name of the `Prometheus` object provided by this library can be overridden:

```jsonnet mdox-exec="cat examples/prometheus-name-override.jsonnet"
((import 'kube-prometheus/main.libsonnet') + {
   prometheus+: {
     prometheus+: {
       metadata+: {
         name: 'my-name',
       },
     },
   },
 }).prometheus.prometheus
```

### node-exporter DaemonSet namespace

Standard Kubernetes manifests are all written using [ksonnet-lib](https://github.com/ksonnet/ksonnet-lib/), so they can be modified with the mixins supplied by ksonnet-lib. For example to override the namespace of the node-exporter DaemonSet:

```jsonnet mdox-exec="cat examples/ksonnet-example.jsonnet"
((import 'kube-prometheus/main.libsonnet') + {
   nodeExporter+: {
     daemonset+: {
       metadata+: {
         namespace: 'my-custom-namespace',
       },
     },
   },
 }).nodeExporter.daemonset
```

### Alertmanager configuration

The Alertmanager configuration is located in the `values.alertmanager.config` configuration field. In order to set a custom Alertmanager configuration simply set this field.

```jsonnet mdox-exec="cat examples/alertmanager-config.jsonnet"
((import 'kube-prometheus/main.libsonnet') + {
   values+:: {
     alertmanager+: {
       config: |||
         global:
           resolve_timeout: 10m
         route:
           group_by: ['job']
           group_wait: 30s
           group_interval: 5m
           repeat_interval: 12h
           receiver: 'null'
           routes:
           - match:
               alertname: Watchdog
             receiver: 'null'
         receivers:
         - name: 'null'
       |||,
     },
   },
 }).alertmanager.secret
```

In the above example the configuration has been inlined, but can just as well be an external file imported in jsonnet via the `importstr` function.

```jsonnet mdox-exec="cat examples/alertmanager-config-external.jsonnet"
((import 'kube-prometheus/main.libsonnet') + {
   values+:: {
     alertmanager+: {
       config: importstr 'alertmanager-config.yaml',
     },
   },
 }).alertmanager.secret
```

### Adding additional namespaces to monitor

In order to monitor additional namespaces, the Prometheus server requires the appropriate `Role` and `RoleBinding` to be able to discover targets from that namespace. By default the Prometheus server is limited to the three namespaces it requires: default, kube-system and the namespace you configure the stack to run in via `$.values.namespace`. This is specified in `$.values.prometheus.namespaces`, to add new namespaces to monitor, simply append the additional namespaces:

```jsonnet mdox-exec="cat examples/additional-namespaces.jsonnet"
local kp = (import 'kube-prometheus/main.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },

    prometheus+: {
      namespaces+: ['my-namespace', 'my-second-namespace'],
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

#### Defining the ServiceMonitor for each additional Namespace

In order to Prometheus be able to discovery and scrape services inside the additional namespaces specified in previous step you need to define a ServiceMonitor resource.

> Typically it is up to the users of a namespace to provision the ServiceMonitor resource, but in case you want to generate it with the same tooling as the rest of the cluster monitoring infrastructure, this is a guide on how to achieve this.

You can define ServiceMonitor resources in your `jsonnet` spec. See the snippet bellow:

```jsonnet mdox-exec="cat examples/additional-namespaces-servicemonitor.jsonnet"
local kp = (import 'kube-prometheus/main.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+:: {
      namespaces+: ['my-namespace', 'my-second-namespace'],
    },
  },
  exampleApplication: {
    serviceMonitorMyNamespace: {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'ServiceMonitor',
      metadata: {
        name: 'my-servicemonitor',
        namespace: 'my-namespace',
      },
      spec: {
        jobLabel: 'app',
        endpoints: [
          {
            port: 'http-metrics',
          },
        ],
        selector: {
          matchLabels: {
            'app.kubernetes.io/name': 'myapp',
          },
        },
      },
    },
  },

};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['example-application-' + name]: kp.exampleApplication[name] for name in std.objectFields(kp.exampleApplication) }
```

> NOTE: make sure your service resources have the right labels (eg. `'app': 'myapp'`) applied. Prometheus uses kubernetes labels to discover resources inside the namespaces.

### Monitoring all namespaces

In case you want to monitor all namespaces in a cluster, you can add the following mixin. Also, make sure to empty the namespaces defined in prometheus so that roleBindings are not created against them.

```jsonnet mdox-exec="cat examples/all-namespaces.jsonnet"
local kp = (import 'kube-prometheus/main.libsonnet') +
           (import 'kube-prometheus/addons/all-namespaces.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+: {
      namespaces: [],
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

> NOTE: This configuration can potentially make your cluster insecure especially in a multi-tenant cluster. This is because this gives Prometheus visibility over the whole cluster which might not be expected in a scenario when certain namespaces are locked down for security reasons.

Proceed with [creating ServiceMonitors for the services in the namespaces](#defining-the-servicemonitor-for-each-additional-namespace) you actually want to monitor

### Static etcd configuration

In order to configure a static etcd cluster to scrape there is a simple [static-etcd.libsonnet](jsonnet/kube-prometheus/addons/static-etcd.libsonnet) mixin prepared - see [etcd.jsonnet](examples/etcd.jsonnet) for an example of how to use that mixin, and [Monitoring external etcd](docs/monitoring-external-etcd.md) for more information.

> Note that monitoring etcd in minikube is currently not possible because of how etcd is setup. (minikube's etcd binds to 127.0.0.1:2379 only, and within host networking namespace.)

### Pod Anti-Affinity

To prevent `Prometheus` and `Alertmanager` instances from being deployed onto the same node when
possible, one can include the [kube-prometheus-anti-affinity.libsonnet](jsonnet/kube-prometheus/addons/anti-affinity.libsonnet) mixin:

```jsonnet mdox-exec="cat examples/anti-affinity.jsonnet"
local kp = (import 'kube-prometheus/main.libsonnet') +
           (import 'kube-prometheus/addons/anti-affinity.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

### Stripping container resource limits

Sometimes in small clusters, the CPU/memory limits can get high enough for alerts to be fired continuously. To prevent this, one can strip off the predefined limits.
To do that, one can import the following mixin

```jsonnet mdox-exec="cat examples/strip-limits.jsonnet"
local kp = (import 'kube-prometheus/main.libsonnet') +
           (import 'kube-prometheus/addons/strip-limits.libsonnet') + {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
  },
};

{ ['00namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{ ['0prometheus-operator-' + name]: kp.prometheusOperator[name] for name in std.objectFields(kp.prometheusOperator) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
```

### Customizing Prometheus alerting/recording rules and Grafana dashboards

See [developing Prometheus rules and Grafana dashboards](docs/developing-prometheus-rules-and-grafana-dashboards.md) guide.

### Exposing Prometheus/Alermanager/Grafana via Ingress

See [exposing Prometheus/Alertmanager/Grafana](docs/exposing-prometheus-alertmanager-grafana-ingress.md) guide.

### Setting up a blackbox exporter

```jsonnet
local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') +
           // ... all necessary mixins ...
  {
    values+:: {
      // ... configuration for other features ...
      blackboxExporter+:: {
        modules+:: {
          tls_connect: {
            prober: 'tcp',
            tcp: {
              tls: true
            }
          }
        }
      }
    }
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
// ... other rendering blocks ...
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) }
```

Then describe the actual blackbox checks you want to run using `Probe` resources. Specify `blackbox-exporter.<namespace>.svc.cluster.local:9115` as the `spec.prober.url` field of the `Probe` resource.

See the [blackbox exporter guide](docs/blackbox-exporter.md) for the list of configurable options and a complete example.

## Minikube Example

To use an easy to reproduce example, see [minikube.jsonnet](examples/minikube.jsonnet), which uses the minikube setup as demonstrated in [Prerequisites](#prerequisites). Because we would like easy access to our Prometheus, Alertmanager and Grafana UIs, `minikube.jsonnet` exposes the services as NodePort type services.

## Continuous Delivery

Working examples of use with continuous delivery tools are found in examples/continuous-delivery.

## Troubleshooting

See the general [guidelines](docs/community-support.md) for getting support from the community.

### Error retrieving kubelet metrics

Should the Prometheus `/targets` page show kubelet targets, but not able to successfully scrape the metrics, then most likely it is a problem with the authentication and authorization setup of the kubelets.

As described in the [Prerequisites](#prerequisites) section, in order to retrieve metrics from the kubelet token authentication and authorization must be enabled. Some Kubernetes setup tools do not enable this by default.

- If you are using Google's GKE product, see [cAdvisor support](docs/GKE-cadvisor-support.md).
- If you are using AWS EKS, see [AWS EKS CNI support](docs/EKS-cni-support.md).
- If you are using Weave Net, see [Weave Net support](docs/weave-net-support.md).

#### Authentication problem

The Prometheus `/targets` page will show the kubelet job with the error `403 Unauthorized`, when token authentication is not enabled. Ensure, that the `--authentication-token-webhook=true` flag is enabled on all kubelet configurations.

#### Authorization problem

The Prometheus `/targets` page will show the kubelet job with the error `401 Unauthorized`, when token authorization is not enabled. Ensure that the `--authorization-mode=Webhook` flag is enabled on all kubelet configurations.

### kube-state-metrics resource usage

In some environments, kube-state-metrics may need additional
resources. One driver for more resource needs, is a high number of
namespaces. There may be others.

kube-state-metrics resource allocation is managed by
[addon-resizer](https://github.com/kubernetes/autoscaler/tree/master/addon-resizer/nanny)
You can control it's parameters by setting variables in the
config. They default to:

```jsonnet
    kubeStateMetrics+:: {
      baseCPU: '100m',
      cpuPerNode: '2m',
      baseMemory: '150Mi',
      memoryPerNode: '30Mi',
    }
```

### Error retrieving kube-proxy metrics

By default, kubeadm will configure kube-proxy to listen on 127.0.0.1 for metrics. Because of this prometheus would not be able to scrape these metrics. This would have to be changed to 0.0.0.0 in one of the following two places:

1. Before cluster initialization, the config file passed to kubeadm init should have KubeProxyConfiguration manifest with the field metricsBindAddress set to 0.0.0.0:10249
2. If the k8s cluster is already up and running, we'll have to modify the configmap kube-proxy in the namespace kube-system and set the metricsBindAddress field. After this kube-proxy daemonset would have to be restarted with
   `kubectl -n kube-system rollout restart daemonset kube-proxy`

## Contributing

All `.yaml` files in the `/manifests` folder are generated via
[Jsonnet](https://jsonnet.org/). Contributing changes will most likely include
the following process:

1. Make your changes in the respective `*.jsonnet` file.
2. Commit your changes (This is currently necessary due to our vendoring
   process. This is likely to change in the future).
3. Update the pinned kube-prometheus dependency in `jsonnetfile.lock.json`: `jb update`
4. Generate dependent `*.yaml` files: `make generate`
5. Commit the generated changes.

## License

Apache License 2.0, see [LICENSE](https://github.com/prometheus-operator/kube-prometheus/blob/main/LICENSE).
