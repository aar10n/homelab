local kp = (import 'kube-prometheus/main.libsonnet');

local defaults = kp + {
  local cfg = self,
  values+:: {
    common+: {
      namespace: 'monitoring',
      platform: 'kubeadm',
    },
    grafana+: {
      hostname: error 'hostname is required',
      config+: {
        sections: {
          analytics: {
            check_for_updates: true,
            reporting_enabled: false,
          },
          server: {
            domain: cfg.values.grafana.hostname,
            root_url: 'https://%s/' % [cfg.values.grafana.hostname],
          }
        }
      },
      datasources: [
        {
          name: 'prometheus',
          type: 'prometheus',
          access: 'proxy',
          url: 'http://prometheus-k8s.%s.svc:9090' % [cfg.values.common.namespace],
        },
      ],
      dashboards: {},
      folderDashboards: {
        Grafana: kp.alertmanager.mixin.grafanaDashboards +
                 kp.grafana.mixin.grafanaDashboards,
        Kubernetes: kp.kubernetesControlPlane.mixin.grafanaDashboards +
                    kp.nodeExporter.mixin.grafanaDashboards,
        Prometheus: kp.prometheus.mixin.grafanaDashboards,
      },
      rawDashboards: {},
      gatewayRef: {
        name: 'gateway',
        namespace: 'projectcontour',
      },
    },
    prometheus+: {
      scrapeClasses: [],
      persistence: {
        enabled: false,
        storageSize: '',
        storageClass: '',
      },
    },
  },
};

function(params) defaults + params + {
  local values = self.values,
  prometheus+:: {
    prometheus+: {
      spec+: {
        retention: values.prometheus.retention,
        scrapeClasses: values.prometheus.scrapeClasses,
        storage: if values.prometheus.persistence.enabled then {
          local persistence = values.prometheus.persistence,
          volumeClaimTemplate: {
            apiVersion: 'v1',
            kind: 'PersistentVolumeClaim',
            spec: {
              accessModes: ['ReadWriteOnce'],
              resources: { requests: { storage: persistence.storageSize } },
              storageClassName: persistence.storageClass,
            },
          },
        },
      },
    },
  },
  grafana+:: {
    httpRoute: {
      apiVersion: 'gateway.networking.k8s.io/v1',
      kind: 'HTTPRoute',
      metadata: {
        name: 'grafana',
        namespace: values.common.namespace,
      },
      spec: {
        hostnames: [values.grafana.hostname],
        parentRefs: [values.grafana.gatewayRef],
        rules: [
          {
            backendRefs: [
              {
                name: 'grafana',
                port: 3000,
              }
            ]
          }
        ],
      },
    },
  },
}
