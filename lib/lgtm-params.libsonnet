{
  lokiImage: 'grafana/loki:2.5.0',
  grafanaImage: 'grafana/grafana:10.4.2',
  tempoImage: 'grafana/tempo:1.4.0',
  mimirImage: 'grafana/mimir:2.9.0',
  replicas: 1,
  namespace: 'lgtm',
  
  // Resource limits to prevent crashes
  resources: {
    limits: {
      memory: '512Mi',
      cpu: '500m'
    },
    requests: {
      memory: '256Mi',
      cpu: '200m'
    }
  }
}

