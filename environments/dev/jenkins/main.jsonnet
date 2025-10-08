{
  // Namespace for Jenkins
  namespace: {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: {
      name: "jenkins",
    },
  },

  // PersistentVolumeClaim for Jenkins data
  pvc: {
    apiVersion: "v1",
    kind: "PersistentVolumeClaim",
    metadata: {
      name: "jenkins-pvc",
      namespace: "jenkins",
    },
    spec: {
      accessModes: ["ReadWriteOnce"],
      resources: {
        requests: {
          storage: "10Gi",
        },
      },
    },
  },

  // Jenkins Deployment
  deployment: {
    apiVersion: "apps/v1",
    kind: "Deployment",
    metadata: {
      name: "jenkins",
      namespace: "jenkins",
      labels: {
        app: "jenkins",
      },
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: {
          app: "jenkins",
        },
      },
      template: {
        metadata: {
          labels: {
            app: "jenkins",
          },
        },
        spec: {
          containers: [
            {
              name: "jenkins",
              image: "jenkins/jenkins:lts",  // latest stable LTS
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
              command: [
                "sh",
                "-c",
                "jenkins-plugin-cli --plugins git github github-branch-source pipeline-model-definition && exec /usr/local/bin/jenkins.sh"
              ],
              env: [
                {
                  name: "JENKINS_OPTS",
                  value: "--httpPort=8080",
                },
              ],
            },
          ],
          volumes: [
            {
              name: "jenkins-data",
              persistentVolumeClaim: {
                claimName: "jenkins-pvc",
              },
            },
          ],
        },
      },
    },
  },

  // Service exposing port 8080 inside cluster (ClusterIP only)
  service: {
    apiVersion: "v1",
    kind: "Service",
    metadata: {
      name: "jenkins",
      namespace: "jenkins",
    },
    spec: {
      type: "ClusterIP",
      selector: {
        app: "jenkins",
      },
      ports: [
        {
          name: "http",
          port: 8080,
          targetPort: 8080,
        },
      ],
    },
  },
}
