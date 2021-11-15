local prometheusingress(name, namespace, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'nginx.ingress.kubernetes.io/auth-type': 'basic',
      'nginx.ingress.kubernetes.io/auth-secret': 'prome-auth',
      'nginx.ingress.kubernetes.io/auth-realm': 'Authentication Required',
    },
  },
  spec: { rules: rules },
};
local grafanaingress(name, namespace, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
  },
  spec: { rules: rules },
};
local alertingress(name, namespace, rules) = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'Ingress',
  metadata: {
    name: name,
    namespace: namespace,
    annotations: {
      'nginx.ingress.kubernetes.io/auth-type': 'basic',
      'nginx.ingress.kubernetes.io/auth-secret': 'alert-auth',
      'nginx.ingress.kubernetes.io/auth-realm': 'Authentication Required',
    },
  },
  spec: { rules: rules },
};

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: 'ops',
      },
      alertmanager+: {
        config: importstr 'alertmanager-config.yaml',
      },
      prometheus+: {
        namespaces+: ['spinnaker', 'staging', 'prod', 'ops', 'istio-system'],
      },
      grafana+:: {
        dashboards+:: {
          'example-dashboard.json': (import 'grafanaDashboard/example-grafana-dashboard.json'),
          'redis-dashboard.json': (import 'grafanaDashboard/redis-grafana-dashboard.json'),
          'istio-control-plane-dashboard.json': (import 'grafanaDashboard/istio-control-plane-dashboard_rev35.json'),
          'istio-mesh-dashboard.json': (import 'grafanaDashboard/istio-mesh-dashboard_rev35.json'),
          'istio-mixer-dashboard.json': (import 'grafanaDashboard/istio-mixer-dashboard_rev35.json'),
          'istio-performance-dashboard.json': (import 'grafanaDashboard/istio-performance-dashboard_rev35.json'),
          'istio-service-dashboard.json': (import 'grafanaDashboard/istio-service-dashboard_rev35.json'),
          'istio-workload-dashboard.json': (import 'grafanaDashboard/istio-workload-dashboard_rev35.json'),
          'application-drilldown-dashboard.json': (import 'grafanaDashboard/application-drilldown-dashboard.json'),
          'aws-platform-dashboard.json': (import 'grafanaDashboard/aws-platform-dashboard.json'),
          'clouddriver-microservice-dashboard.json': (import 'grafanaDashboard/clouddriver-microservice-dashboard.json'),
          'echo-microservice-dashboard.json': (import 'grafanaDashboard/echo-microservice-dashboard.json'),
          'fiat-microservice-dashboard.json': (import 'grafanaDashboard/fiat-microservice-dashboard.json'),
          'front50-microservice-dashboard.json': (import 'grafanaDashboard/front50-microservice-dashboard.json'),
          'gate-microservice-dashboard.json': (import 'grafanaDashboard/gate-microservice-dashboard.json'),
          'google-platform-dashboard.json': (import 'grafanaDashboard/google-platform-dashboard.json'),
          'igor-microservice-dashboard.json': (import 'grafanaDashboard/igor-microservice-dashboard.json'),
          'kubernetes-platform-dashboard.json': (import 'grafanaDashboard/kubernetes-platform-dashboard.json'),
          'machine-dashboard.json': (import 'grafanaDashboard/machine-dashboard.json'),
          'minimal-spinnaker-dashboard.json': (import 'grafanaDashboard/minimal-spinnaker-dashboard.json'),
          'orca-microservice-dashboard.json': (import 'grafanaDashboard/orca-microservice-dashboard.json'),
          'rosco-microservice-dashboard.json': (import 'grafanaDashboard/rosco-microservice-dashboard.json'),
          'grafana-jenkins-status.json': (import 'grafanaDashboard/grafana-jenkins-status.json'),
          //'sonarqube-dashboard.json': (import 'grafanaDashboard/sonarqube-dashboard.json'),
        },
        config+: {
          sections+: {
            'auth.ldap'+: {
              enabled: true,
              config_file: '/etc/grafana/ldap.toml',
              allow_sign_up: true,
            },
            security+: {
              admin_password: 'STRNalEzTjBFdFJFUTVReTAwTWtF',
              admin_user: 'admin',
              allow_embedding: true,
            },
            server+: {
              root_url: 'http://grafana.formovie.com/',
            },
          },
        },
        ldap: |||
          [[servers]]
          host = "120.92.116.22"
          port = 30389
          use_ssl = false
          start_tls = false
          ssl_skip_verify = false
          bind_dn = "cn=jenkins,dc=formovie,dc=cn"
          bind_password = 'jenkins2018'
          search_filter = "(cn=%s)"
          search_base_dns = ["dc=formovie,dc=cn"]
          [servers.attributes]
          name = "givenName"
          surname = "sn"
          username = "cn"
          member_of = "memberOf"
          email =  "email"

          [[servers.group_mappings]]
          group_dn = "cn=fm-devs,dc=formovie,dc=cn"
          org_role = "Admin"

          [[servers.group_mappings]]
          group_dn = "*"
          org_role = "Viewer"
        |||,
      },
    },
    // Configure External URL's per application
    alertmanager+:: {
      alertmanager+: {
        spec+: {
          externalUrl: 'http://alertmanager.formovie.com',
        },
      },
    },
    prometheus+:: {
      prometheus+: {
        spec+: {
          externalUrl: 'http://prometheus.formovie.com',
          retention: '60d',
          ruleNamespaceSelector: {},
          storage: {
            volumeClaimTemplate: {
              apiVersion: 'v1',
              kind: 'PersistentVolumeClaim',
              spec: {
                accessModes: ['ReadWriteOnce'],
                resources: { requests: { storage: '2000Gi' } },
                storageClassName: 'alicloud-nas',
              },
            },
          },    
        },
      },
    },
    // Create ingress objects per application
    ingress+:: {
      'alertmanager-main': alertingress(
        'alertmanager-main',
        $.values.common.namespace,
        [{
          host: 'alertmanager.formovie.com',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'alertmanager-main',
                  port: {
                    name: 'web',
                  },
                },
              },
            }],
          },
        }]
      ),
      grafana: grafanaingress(
        'grafana',
        $.values.common.namespace,
        [{
          host: 'grafana.formovie.com',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'grafana',
                  port: {
                    name: 'http',
                  },
                },
              },
            }],
          },
        }],
      ),
      'prometheus-k8s': prometheusingress(
        'prometheus-k8s',
        $.values.common.namespace,
        [{
          host: 'prometheus.formovie.com',
          http: {
            paths: [{
              path: '/',
              pathType: 'Prefix',
              backend: {
                service: {
                  name: 'prometheus-k8s',
                  port: {
                    name: 'web',
                  },
                },
              },
            }],
          },
        }],
      ),
    },
  } + {
    // Create basic auth secret - replace 'auth' file with your own
    ingress+:: {
      'prome-auth-secret': {
        apiVersion: 'v1',
        kind: 'Secret',
        metadata: {
          name: 'prome-auth',
          namespace: $.values.common.namespace,
        },
        data: { auth: std.base64(importstr 'prome-auth') },
        type: 'Opaque',
      },
      'alert-auth-secret': {
        apiVersion: 'v1',
        kind: 'Secret',
        metadata: {
          name: 'alert-auth',
          namespace: $.values.common.namespace,
        },
        data: { auth: std.base64(importstr 'alert-auth') },
        type: 'Opaque',
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
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['ingress-' + name]: kp.ingress[name] for name in std.objectFields(kp.ingress) }
