{
  new(name, namespace, port):: {
    deployment: {  // Deployment configuration
      apiVersion: "apps/v1",
      kind: "Deployment",
      metadata: {
        name: name,
        namespace: namespace,
      },
      spec: {
        replicas: 1,
        selector: {
          matchLabels: { app: name },
        },
        template: {
          metadata: {
            labels: { app: name },
          },
          spec: {
            containers: [
              {
                name: name,
                image: "grafana/loki:2.3.0",
                ports: [
                  { containerPort: port, name: "http" },
                ],
                volumeMounts: [
                  {
                    name: "config-volume",  // Mount point
                    mountPath: "/etc/loki",  // Mount the configuration at this path
                  },
                ],
              },
            ],
            volumes: [
              {
                name: "config-volume",
                configMap: {
                  name: name + "-config",  // Referencing the ConfigMap we will create inline
                },
              },
            ],
          },
        },
      },
    },

    service: {  // Service configuration for Loki
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        name: name,
        namespace: namespace,
        labels: { app: name },
      },
      spec: {
        selector: { app: name },
        ports: [
          {
            protocol: "TCP",
            port: port,
            targetPort: port,
            name: "http",
          },
        ],
        type: "NodePort",
      },
    },

    configMap: {  // Inline Loki configuration in the ConfigMap
      apiVersion: "v1",
      kind: "ConfigMap",
      metadata: {
        name: name + "-config",
        namespace: namespace,
      },
      data: {
        "loki-config.yaml": '''
          auth_enabled: false
          server:
            http_listen_port: 3100
            grpc_listen_port: 9096
          ingester:
            chunk_idle_period: 5m
            chunk_block_size: 262144
            max_chunk_age: 1h
            max_request_size: 10485760
            ring:
              kvstore:
                store: inmemory
              replication_factor: 1
              instance_count: 1
          storage_config:
            boltdb_shipper:
              active_index_directory: /data/loki/index
              cache_location: /data/loki/cache
              shared_store: filesystem
            filesystem:
              directory: /data/loki/chunks
          limits_config:
            ingestion_rate_mb: 5
            ingestion_rate_strategy: global
            max_query_parallelism: 32
            max_streams_per_user: 10000
          query_range:
            max_retries: 5
            cache_results: true
            results_cache:
              enabled: true
              size: 100MB
              ttl: 30s
        '''
      },
    },  // Make sure this comma is placed correctly
  },  // Closing the object here
}

