{
  // Namespace
  my_namespace: {
    apiVersion: "v1",
    kind: "Namespace",
    metadata :{
      name: "monitoring",
    },
  },

  // Grafana
  grafana: {
    deployment: {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'grafana',
        namespace: 'monitoring',
      },
      spec: {
        selector: {
          matchLabels: {
            name: 'grafana',
          },
        },
        template: {
          metadata: {
            labels: {
              name: 'grafana',
            },
          },
          spec: {
            containers: [
              {
                image: 'grafana/grafana',
                name: 'grafana',
                ports: [{
                    containerPort: 3000,
                    name: 'ui',
                }],
              },
            ],
          },
        },
      },
    },
    service: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        labels: {
          name: 'grafana',
        },
        name: 'grafana',
        namespace: 'monitoring',
      },
      spec: {
        ports: [{
            name: 'grafana-ui',
            port: 3000,
            targetPort: 3000,
        }],
        selector: {
          name: 'grafana',
        },
        type: 'NodePort',
      },
    },
  },

  // Prometheus
  prometheus: {
    deployment: {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'prometheus',
        namespace: 'monitoring',
      },
      spec: {
        minReadySeconds: 10,
        replicas: 1,
        revisionHistoryLimit: 10,
        selector: {
          matchLabels: {
            name: 'prometheus',
          },
        },
        template: {
          metadata: {
            labels: {
              name: 'prometheus',
            },
          },
          spec: {
            containers: [
              {
                image: 'prom/prometheus',
                imagePullPolicy: 'IfNotPresent',
                name: 'prometheus',
                ports: [
                  {
                    containerPort: 9090,
                    name: 'api',
                  },
                ],
              },
            ],
          },
        },
      },
    },
    service: {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        labels: {
          name: 'prometheus',
        },
        name: 'prometheus',
        namespace: 'monitoring',
      },
      spec: {
        ports: [
          {
            name: 'prometheus-api',
            port: 9090,
            targetPort: 9090,
          },
        ],
        selector: {
          name: 'prometheus',
        },
      },
    },
  },
}
