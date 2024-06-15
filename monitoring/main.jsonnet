# jsonnet -y main.jsonnet
local m = (import 'monitoring.libsonnet')({
  values+:: {
    common+: {},
    grafana+: {
      hostname: 'grafana.home.agb.dev',
      config+: {
        sections+: {
          database: {
            type: 'postgres',
            host: 'postgres.home.agb.dev',
            name: 'grafana',
            user: 'grafana',
            password: 'grafana',
          },
        }
      },
    },
    prometheus+: {
      retention: '1d',
      persistence: {
        enabled: true,
        storageSize: '10Gi',
        storageClass: 'openebs-hostpath',
      },
      scrapeClasses: [
        {
          name: 'prometheus',
          default: true,
          relabelings: [
            {
              sourceLabels: ['__address__'],
              targetLabel: 'cluster',
              replacement: 'k8s_cluster',
            },
          ],
        }
      ],
    }
  },
});


if std.extVar("setup") == 'true' then
  [m.kubePrometheus.namespace] +
  [
    item for item in std.objectValues(m.prometheusOperator)
    if item.kind != 'ServiceMonitor' && item.kind != 'PrometheusRule'
  ]
else
  [m.prometheusOperator.serviceMonitor] +
  [m.prometheusOperator.prometheusRule] +
  [m.kubePrometheus.prometheusRule] +
  std.objectValues(m.alertmanager) +
  std.objectValues(m.kubeStateMetrics) +
  std.objectValues(m.kubernetesControlPlane) +
  std.objectValues(m.nodeExporter) +
  std.objectValues(m.prometheus) +
  std.objectValues(m.prometheusAdapter) +
  std.objectValues(m.grafana)
