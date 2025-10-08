local k = import 'k.libsonnet';
local params = import '../../../lib/lgtm-params.libsonnet';

{
  // Namespace
  lgtmNamespace: k.core.v1.namespace.new(name = params.namespace),

  //
  // Loki
  lokiDeployment: k.apps.v1.deployment.new(
    name = 'loki',
    replicas = params.replicas,
    containers = [
      k.core.v1.container.new('loki', params.lokiImage)
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(3100)])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('data', '/var/loki')
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'loki' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'loki' })
  + k.apps.v1.deployment.spec.template.spec.withVolumes([
    { name: 'data', persistentVolumeClaim: { claimName: 'loki-data-pvc' } }
  ]),

  lokiService: k.core.v1.service.new(
    name = 'loki',
    selector = { app: 'loki' },
    ports = [ k.core.v1.servicePort.new(3100, 3100) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  //
  // Grafana
  grafanaDeployment: k.apps.v1.deployment.new(
    name = 'grafana',
    replicas = params.replicas,
    containers = [
      k.core.v1.container.new('grafana', params.grafanaImage)
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(3000)])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('datasources', '/etc/grafana/provisioning/datasources')
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'grafana' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'grafana' })
  + k.apps.v1.deployment.spec.template.spec.withVolumes([
    { name: 'datasources', configMap: { name: 'grafana-datasources' } }
  ]),

  grafanaService: k.core.v1.service.new(
    name = 'grafana',
    selector = { app: 'grafana' },
    ports = [ k.core.v1.servicePort.new(3000, 3000) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  grafanaDatasourceConfig: k.core.v1.configMap.new(
    name = 'grafana-datasources',
    data = {
      "datasources.yaml": |||
        apiVersion: 1
        datasources:
          - name: Mimir
            type: prometheus
            access: proxy
            url: http://mimir.lgtm.svc.cluster.local:9000/prometheus
            isDefault: true
      |||
    }
  )
  + k.core.v1.configMap.metadata.withNamespace(params.namespace),

  //
  // Tempo
  tempoDeployment: k.apps.v1.deployment.new(
    name = 'tempo',
    replicas = params.replicas,
    containers = [
      k.core.v1.container.new('tempo', params.tempoImage)
      + k.core.v1.container.withArgs([
        '--storage.trace.backend=local',
        '--storage.trace.local.path=/tmp/tempo',
        '--storage.trace.wal.path=/var/tempo/wal',
        '--server.http-listen-port=5778'
      ])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('tempo-storage', '/tmp/tempo'),
        k.core.v1.volumeMount.new('tempo-wal', '/var/tempo/wal')
      ])
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(5778)])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'tempo' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'tempo' })
  + k.apps.v1.deployment.spec.template.spec.withInitContainers([
    k.core.v1.container.new('init-permissions', 'busybox')
    + k.core.v1.container.withCommand(['sh', '-c', 'mkdir -p /tmp/tempo /var/tempo/wal && chmod -R 777 /tmp/tempo /var/tempo/wal'])
    + k.core.v1.container.withVolumeMounts([
      k.core.v1.volumeMount.new('tempo-storage', '/tmp/tempo'),
      k.core.v1.volumeMount.new('tempo-wal', '/var/tempo/wal')
    ])
  ])
  + k.apps.v1.deployment.spec.template.spec.withVolumes([
    { name: 'tempo-storage', persistentVolumeClaim: { claimName: 'tempo-storage-pvc' } },
    { name: 'tempo-wal', persistentVolumeClaim: { claimName: 'tempo-wal-pvc' } }
  ]),

  tempoService: k.core.v1.service.new(
    name = 'tempo',
    selector = { app: 'tempo' },
    ports = [ k.core.v1.servicePort.new(5778, 5778) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  //
  // Mimir
  mimirDeployment: k.apps.v1.deployment.new(
    name = 'mimir',
    replicas = params.replicas,
    containers = [
      k.core.v1.container.new('mimir', params.mimirImage)
      + k.core.v1.container.withArgs([
        "-target=all",
        "-server.http-listen-port=9000",
        "-auth.multitenancy-enabled=false",
        "-blocks-storage.backend=filesystem",
        "-blocks-storage.filesystem.dir=/tmp/mimir",
        "-distributor.ring.store=inmemory",
        "-ingester.ring.store=inmemory",
        "-compactor.ring.store=inmemory",
        "-store-gateway.sharding-ring.store=inmemory",
        "-memberlist.join=",
        "-ingester.ring.replication-factor=1"
      ])
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(9000)])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('data', '/tmp/mimir')
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'mimir' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'mimir' })
  + k.apps.v1.deployment.spec.template.spec.withVolumes([
    { name: 'data', persistentVolumeClaim: { claimName: 'mimir-data-pvc' } }
  ]),

  mimirService: k.core.v1.service.new(
    name = 'mimir',
    selector = { app: 'mimir' },
    ports = [ k.core.v1.servicePort.new(9000, 9000) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  //
  // kube-state-metrics
  kubeStateMetricsDeployment: k.apps.v1.deployment.new(
    name = 'kube-state-metrics',
    replicas = 1,
    containers = [
      k.core.v1.container.new(
        name = 'kube-state-metrics',
        image = 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.17.0'
      )
      + k.core.v1.container.withPorts([ k.core.v1.containerPort.new(8080) ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'kube-state-metrics' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'kube-state-metrics' })
  + k.apps.v1.deployment.spec.template.spec.withServiceAccountName('kube-state-metrics'),

  kubeStateMetricsService: k.core.v1.service.new(
    name = 'kube-state-metrics',
    selector = { app: 'kube-state-metrics' },
    ports = [ k.core.v1.servicePort.new(8080, 8080) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

    //
  // Prometheus config with static node-exporter job
  prometheusConfig: k.core.v1.configMap.new(
    name = 'prometheus-config',
    data = {
      'prometheus.yml':
        'global:\n' +
        '  scrape_interval: 15s\n\n' +
        'scrape_configs:\n' +
        '  - job_name: "kubernetes-pods"\n' +
        '    kubernetes_sd_configs:\n' +
        '      - role: pod\n' +
        '        namespaces:\n' +
        '          names: ["lgtm", "default"]\n' +
        '    relabel_configs:\n' +
        '      - source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]\n' +
        '        action: keep\n' +
        '        regex: "true"\n' +
        '      - source_labels: ["__meta_kubernetes_pod_annotation_prometheus_io_path"]\n' +
        '        action: replace\n' +
        '        target_label: __metrics_path__\n' +
        '        regex: "(.+)"\n' +
        '      - source_labels: ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]\n' +
        '        action: replace\n' +
        '        regex: "([^:]+)(?::\\\\d+)?;(\\\\d+)"\n' +
        '        replacement: "$1:$2"\n' +
        '        target_label: __address__\n' +
        '      - source_labels: ["__meta_kubernetes_pod_label_app"]\n' +
        '        target_label: app\n' +
        '      - source_labels: ["__meta_kubernetes_namespace"]\n' +
        '        target_label: kubernetes_namespace\n' +
        '      - source_labels: ["__meta_kubernetes_pod_name"]\n' +
        '        target_label: kubernetes_pod_name\n\n' +
        '  - job_name: "kube-state-metrics"\n' +
        '    static_configs:\n' +
        '      - targets: ["kube-state-metrics.' + params.namespace + '.svc.cluster.local:8080"]\n\n' +
        '  - job_name: "node-exporter"\n' +
        '    static_configs:\n' +
        '      - targets: ["node-exporter.' + params.namespace + '.svc.cluster.local:9100"]\n\n' +
        '  - job_name: "kubelet"\n' +
        '    scheme: https\n' +
        '    metrics_path: /metrics\n' +
        '    kubernetes_sd_configs:\n' +
        '      - role: node\n' +
        '    tls_config:\n' +
        '      insecure_skip_verify: true\n' +
        '    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n' +
        '    relabel_configs:\n' +
        '      - source_labels: ["__address__"]\n' +
        '        regex: "([^:]+)(?::\\\\d+)?"\n' +
        '        replacement: "${1}:10250"\n' +
        '        target_label: __address__\n\n' +
        '  - job_name: "kubelet-cadvisor"\n' +
        '    scheme: https\n' +
        '    metrics_path: /metrics/cadvisor\n' +
        '    kubernetes_sd_configs:\n' +
        '      - role: node\n' +
        '    tls_config:\n' +
        '      insecure_skip_verify: true\n' +
        '    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token\n' +
        '    relabel_configs:\n' +
        '      - source_labels: ["__address__"]\n' +
        '        regex: "([^:]+)(?::\\\\d+)?"\n' +
        '        replacement: "${1}:10250"\n' +
        '        target_label: __address__\n\n' +
        'remote_write:\n' +
        '  - url: "http://mimir.' + params.namespace + '.svc.cluster.local:9000/api/v1/push"\n',
    }
  )
  + k.core.v1.configMap.metadata.withNamespace(params.namespace),

  //
  // Prometheus Agent
  prometheusAgentDeployment: k.apps.v1.deployment.new(
    name = 'prometheus-agent',
    replicas = 1,
    containers = [
      k.core.v1.container.new('prometheus-agent', 'prom/prometheus:v2.52.0')
      + k.core.v1.container.withArgs([
        '--config.file=/etc/prometheus/prometheus.yml',
        '--enable-feature=agent',
        '--log.level=info',
        '--web.enable-lifecycle'
      ])
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(9090)])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('config', '/etc/prometheus'),
        k.core.v1.volumeMount.new('data', '/prometheus')
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({ app: 'prometheus-agent' })
  + k.apps.v1.deployment.spec.template.metadata.withLabels({ app: 'prometheus-agent' })
  + k.apps.v1.deployment.spec.template.spec.withServiceAccountName('prometheus-agent')
  + k.apps.v1.deployment.spec.template.spec.withVolumes([
    { name: 'config', configMap: { name: 'prometheus-config' } },
    { name: 'data', emptyDir: {} }
  ]),

  prometheusAgentService: k.core.v1.service.new(
    name = 'prometheus-agent',
    selector = { app: 'prometheus-agent' },
    ports = [ k.core.v1.servicePort.new(9090, 9090) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  prometheusServiceAccount: k.core.v1.serviceAccount.new('prometheus-agent')
  + k.core.v1.serviceAccount.metadata.withNamespace(params.namespace),

  prometheusClusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: { name: 'prometheus-agent' },
    rules: [
      {
        apiGroups: [''],
        resources: ['nodes', 'nodes/metrics', 'services', 'endpoints', 'pods', 'namespaces'],
        verbs: ['get', 'list', 'watch'],
      },
      {
        apiGroups: ['extensions', 'apps'],
        resources: ['replicasets', 'deployments'],
        verbs: ['get', 'list', 'watch'],
      },
      {
        nonResourceURLs: ['/metrics', '/metrics/cadvisor'],
        verbs: ['get'],
      },
    ],
  },

  prometheusClusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: { name: 'prometheus-agent' },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'prometheus-agent',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'prometheus-agent',
        namespace: params.namespace,
      },
    ],
  },

  // kube-state-metrics ServiceAccount
  kubeStateMetricsServiceAccount: k.core.v1.serviceAccount.new('kube-state-metrics')
  + k.core.v1.serviceAccount.metadata.withNamespace(params.namespace),

  // kube-state-metrics ClusterRole
  kubeStateMetricsClusterRole: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRole',
    metadata: { name: 'kube-state-metrics' },
    rules: [
      {
        apiGroups: [''],
        resources: ['nodes', 'pods', 'services', 'endpoints', 'secrets', 'configmaps', 'namespaces', 'replicationcontrollers', 'limitranges', 'persistentvolumeclaims', 'persistentvolumes', 'resourcequotas'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['apps'],
        resources: ['deployments', 'daemonsets', 'replicasets', 'statefulsets'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['batch'],
        resources: ['cronjobs', 'jobs'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['autoscaling'],
        resources: ['horizontalpodautoscalers'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['networking.k8s.io'],
        resources: ['networkpolicies', 'ingresses'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['storage.k8s.io'],
        resources: ['storageclasses', 'volumeattachments'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['policy'],
        resources: ['poddisruptionbudgets'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['certificates.k8s.io'],
        resources: ['certificatesigningrequests'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['coordination.k8s.io'],
        resources: ['leases'],
        verbs: ['list', 'watch'],
      },
      {
        apiGroups: ['admissionregistration.k8s.io'],
        resources: ['mutatingwebhookconfigurations', 'validatingwebhookconfigurations'],
        verbs: ['list', 'watch'],
      },
    ],
  },

  // kube-state-metrics ClusterRoleBinding
  kubeStateMetricsClusterRoleBinding: {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: { name: 'kube-state-metrics' },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'kube-state-metrics',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'kube-state-metrics',
        namespace: params.namespace,
      },
    ],
  },

  //
  // Node Exporter
  nodeExporterDaemonSet: k.apps.v1.daemonSet.new(
    name = 'node-exporter',
    containers = [
      k.core.v1.container.new('node-exporter', 'quay.io/prometheus/node-exporter:v1.8.1')
      + k.core.v1.container.withPorts([k.core.v1.containerPort.new(9100)])
      + k.core.v1.container.withArgs([
        '--path.rootfs=/host'
      ])
      + k.core.v1.container.withVolumeMounts([
        k.core.v1.volumeMount.new('root', '/host', true)
      ])
    ]
  )
  + k.apps.v1.daemonSet.metadata.withNamespace(params.namespace)
  + k.apps.v1.daemonSet.spec.selector.withMatchLabels({ app: 'node-exporter' })
  + k.apps.v1.daemonSet.spec.template.metadata.withLabels({ app: 'node-exporter' })
  + k.apps.v1.daemonSet.spec.template.metadata.withAnnotations({
      'prometheus.io/scrape': 'true',
      'prometheus.io/port': '9100',
    })
  + k.apps.v1.daemonSet.spec.template.spec.withHostNetwork(true)
  + k.apps.v1.daemonSet.spec.template.spec.withVolumes([
      { name: 'root', hostPath: { path: '/' } }
    ]),

  nodeExporterService: k.core.v1.service.new(
    name = 'node-exporter',
    selector = { app: 'node-exporter' },
    ports = [ k.core.v1.servicePort.new(9100, 9100) ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  //
  // PVCs
  prometheusDataPVC:
    k.core.v1.persistentVolumeClaim.new('prometheus-data-pvc')
    + k.core.v1.persistentVolumeClaim.metadata.withNamespace(params.namespace)
    + { spec+: { accessModes: ['ReadWriteOnce'], resources: { requests: { storage: '10Gi' } } } },

  mimirPVC:
    k.core.v1.persistentVolumeClaim.new('mimir-data-pvc')
    + k.core.v1.persistentVolumeClaim.metadata.withNamespace(params.namespace)
    + { spec+: { accessModes: ['ReadWriteOnce'], resources: { requests: { storage: '10Gi' } } } },

   lokiPVC:
    k.core.v1.persistentVolumeClaim.new('loki-data-pvc')
    + k.core.v1.persistentVolumeClaim.metadata.withNamespace(params.namespace)
    + { spec+: { accessModes: ['ReadWriteOnce'], resources: { requests: { storage: '10Gi' } } } },

  tempoStoragePVC:
    k.core.v1.persistentVolumeClaim.new('tempo-storage-pvc')
    + k.core.v1.persistentVolumeClaim.metadata.withNamespace(params.namespace)
    + { spec+: { accessModes: ['ReadWriteOnce'], resources: { requests: { storage: '10Gi' } } } },

  tempoWalPVC:
    k.core.v1.persistentVolumeClaim.new('tempo-wal-pvc')
    + k.core.v1.persistentVolumeClaim.metadata.withNamespace(params.namespace)
    + { spec+: { accessModes: ['ReadWriteOnce'], resources: { requests: { storage: '5Gi' } } } },
}

