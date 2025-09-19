local grafana = import "../../lib/grafana.libsonnet";
local prometheus = import "../../lib/prometheus.libsonnet";

{
  namespace: {
  apiVersion: "v1",
  kind:  "Namespace",
  metadata: {name: "monitoring-dev"},
 },


  grafana: grafana.new("grafana-dev", "monitoring-dev", 3000),
  prometheus: prometheus.new("prometheus-dev", "monitoring-dev", 9090),
}

