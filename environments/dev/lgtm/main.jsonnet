
local k = import 'k.libsonnet';
local params = import '../../../lib/lgtm-params.libsonnet';

// Create namespace for LGTM stack
{
  lgtmNamespace: k.core.v1.namespace.new(
    name=params.namespace
  ),

  // Loki Deployment
  lokiDeployment: k.apps.v1.deployment.new(
    name='loki',
    replicas=params.replicas,
    containers=[
      k.core.v1.container.new(
        name='loki',
        image=params.lokiImage
      )
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.new(3100)
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({app: 'loki'})
  + k.apps.v1.deployment.spec.template.metadata.withLabels({app: 'loki'}),

  // Grafana Deployment
  grafanaDeployment: k.apps.v1.deployment.new(
    name='grafana',
    replicas=params.replicas,
    containers=[
      k.core.v1.container.new(
        name='grafana',
        image=params.grafanaImage
      )
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.new(3000)
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({app: 'grafana'})
  + k.apps.v1.deployment.spec.template.metadata.withLabels({app: 'grafana'}),

  
  // Tempo Deployment with initContainer added
tempoDeployment: k.apps.v1.deployment.new(
  name='tempo',
  replicas=params.replicas,
  containers=[
    k.core.v1.container.new(
      name='tempo',
      image=params.tempoImage
    )
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
    + k.core.v1.container.withPorts([
      k.core.v1.containerPort.new(5778)
    ])
  ]
)
+ k.apps.v1.deployment.metadata.withNamespace(params.namespace)
+ k.apps.v1.deployment.spec.selector.withMatchLabels({app: 'tempo'})
+ k.apps.v1.deployment.spec.template.metadata.withLabels({app: 'tempo'})
+ k.apps.v1.deployment.spec.template.spec.withInitContainers([
  k.core.v1.container.new(
    'init-permissions',
    'busybox'
  )
  + k.core.v1.container.withCommand(['sh', '-c', 'mkdir -p /tmp/tempo /var/tempo/wal && chmod -R 777 /tmp/tempo /var/tempo/wal'])
  + k.core.v1.container.withVolumeMounts([
    k.core.v1.volumeMount.new('tempo-storage', '/tmp/tempo'),
    k.core.v1.volumeMount.new('tempo-wal', '/var/tempo/wal')
  ])
])
+ k.apps.v1.deployment.spec.template.spec.withVolumes([
  {
    name: 'tempo-storage',
    emptyDir: {}
  },
  {
    name: 'tempo-wal',
    emptyDir: {}
  }
]),


  // Mimir Deployment
  mimirDeployment: k.apps.v1.deployment.new(
    name='mimir',
    replicas=params.replicas,
    containers=[
      k.core.v1.container.new(
        name='mimir',
        image=params.mimirImage
      )
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.new(9000)
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({app: 'mimir'})
  + k.apps.v1.deployment.spec.template.metadata.withLabels({app: 'mimir'}),

  // Services for each component
  lokiService: k.core.v1.service.new(
    name='loki',
    selector={app: 'loki'},
    ports=[
      k.core.v1.servicePort.new(
        port=3100,
        targetPort=3100
      )
    ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  grafanaService: k.core.v1.service.new(
    name='grafana',
    selector={app: 'grafana'},
    ports=[
      k.core.v1.servicePort.new(
        port=3000,
        targetPort=3000
      )
    ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  tempoService: k.core.v1.service.new(
    name='tempo',
    selector={app: 'tempo'},
    ports=[
      k.core.v1.servicePort.new(
        port=5778,
        targetPort=5778
      )
    ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),

  mimirService: k.core.v1.service.new(
    name='mimir',
    selector={app: 'mimir'},
    ports=[
      k.core.v1.servicePort.new(
        port=9000,
        targetPort=9000
      )
    ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),
}

