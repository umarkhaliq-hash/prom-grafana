// lib/monitoring.libsonnet
{
  monitoring(name, namespace, grafanaPort=3000, promPort=9090):
    {
      namespaceObj: {
        apiVersion: "v1",
        kind: "Namespace",
        metadata: { name: namespace },
      },

      grafanaService: {
        apiVersion: "v1",
        kind: "Service",
        metadata: {
          name: "%s-grafana" % name,
          namespace: namespace,
        },
        spec: {
          ports: [
            {
              name: "grafana-ui",
              port: grafanaPort,
              targetPort: 3000,
            },
          ],
          selector: { app: "grafana" },
          type: "NodePort",
        },
      },

      prometheusService: {
        apiVersion: "v1",
        kind: "Service",
        metadata: {
          name: "%s-prometheus" % name,
          namespace: namespace,
        },
        spec: {
          ports: [
            {
              name: "prometheus-ui",
              port: promPort,
              targetPort: 9090,
            },
          ],
          selector: { app: "prometheus" },
          type: "NodePort",
        },
      },
    },
}

