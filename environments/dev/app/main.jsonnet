local k = import 'k.libsonnet';
local params = import '../../../lib/app.libsonnet';

{
  // Create namespace resource
  namespace: k.core.v1.namespace.new(params.namespace),

  // Deployment resource
  deployment: k.apps.v1.deployment.new(
    name=params.appName,
    replicas=params.replicas,
    containers=[
      k.core.v1.container.new(
        name=params.appName,
        image=params.image
      )
      + k.core.v1.container.withPorts([
        k.core.v1.containerPort.new(params.containerPort)
      ])
      + k.core.v1.container.withEnv([
        k.core.v1.envVar.new("APP_NAME", "devops-screener"),
        k.core.v1.envVar.new("APP_ENV", "development"),
        k.core.v1.envVar.new("PORT", "5000"),
      ])
    ]
  )
  + k.apps.v1.deployment.metadata.withNamespace(params.namespace)
  + k.apps.v1.deployment.spec.selector.withMatchLabels({app: params.appName})
  + k.apps.v1.deployment.spec.template.metadata.withLabels({app: params.appName}),

  // Service resource
  service: k.core.v1.service.new(
    name=params.appName,
    selector={app: params.appName},
    ports=[
      k.core.v1.servicePort.new(
        port=5000,
        targetPort=params.containerPort
      )
    ]
  )
  + k.core.v1.service.metadata.withNamespace(params.namespace),
}

