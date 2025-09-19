{
  deployment: {
    new(name, containers):: {
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        name: name,
      },
      spec: {
        selector: {
          matchLabels: { name: name },
        },
        template: {
          metadata: { labels: { name: name } },
          spec: { containers: containers },
        },
      },
    },
  },

  service: {
    new(name, port):: {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        name: name,
        labels: { name: name },
      },
      spec: {
        selector: { name: name },
        ports: [{
          name: "%s-port" % name,
          port: port,
          targetPort: port,
        }],
        type: "NodePort",
      },
    },
  },
}

