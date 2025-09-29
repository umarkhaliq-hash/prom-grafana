{
  // Namespace definition
  namespace: {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: {
      name: "jenkins",
    },
  },

  // Jenkins Deployment
  deployment: {
    apiVersion: "apps/v1",
    kind: "Deployment",
    metadata: {
      name: "jenkins",
      namespace: "jenkins",
      labels: { app: "jenkins" },
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: { app: "jenkins" },
      },
      template: {
        metadata: {
          labels: { app: "jenkins" },
        },
        spec: {
          containers: [
            {
              name: "jenkins",
              image: "jenkins/jenkins:lts",
              ports: [
                { name: "http", containerPort: 8080 },
                { name: "jnlp", containerPort: 50000 },
              ],
              volumeMounts: [
                {
                  name: "jenkins-data",
                  mountPath: "/var/jenkins_home",
                },
              ],
            },
          ],
          volumes: [
            {
              name: "jenkins-data",
              emptyDir: {},
            },
          ],
        },
      },
    },
  },

  // Jenkins Service
  service: {
    apiVersion: "v1",
    kind: "Service",
    metadata: {
      name: "jenkins",
      namespace: "jenkins",
    },
    spec: {
      selector: { app: "jenkins" },
      ports: [
        {
          port: 8080,
          targetPort: 8080,
          name: "http",
        },
      ],
      type: "NodePort",
    },
  },
}

