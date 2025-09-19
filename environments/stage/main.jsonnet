local grafana = import "../../lib/grafana.libsonnet";
local prometheus = import "../../lib/prometheus.libsonnet";

{
 namespace: {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: { name: "monitoring-stage" },
  },
  grafana: grafana.new("grafana-stage", "monitoring-stage", 3000),
  prometheus: prometheus.new("prometheus-stage", "monitoring-stage", 9090),
}

