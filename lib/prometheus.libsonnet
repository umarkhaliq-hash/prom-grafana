{
  new(name, namespace, port):: {
    deployment: {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        name: name,
        namespace: namespace,
      },
      spec: {
        selector: {
          matchLabels: { app: name },
        },
        template: {
          metadata: { labels: { app: name } },
          spec: {
            containers: [{
              name: name,
              image: "prom/prometheus",
              ports: [{ containerPort: port, name: "api" }],
            }],
          },
        },
      },
    },

    service: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        name: name,
        namespace: namespace,
        labels: { app: name },
      },
      spec: {
        selector: { app: name },
        ports: [{
          name: "http",
          port: port,
          targetPort: port,
        }],
        type: "NodePort",
      },
    },
  },
}

