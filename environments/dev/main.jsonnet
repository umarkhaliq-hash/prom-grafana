local grafana = import "../../lib/grafana.libsonnet";
local prometheus = import "../../lib/prometheus.libsonnet";
#local loki = import "../../lib/loki.libsonnet";  // Add Loki impo

{
  namespace: {
  apiVersion: "v1",
  kind:  "Namespace",
  metadata: {name: "monitoring-dev"},
 },


  grafana: grafana.new("grafana-dev", "monitoring-dev", 3000),
  prometheus: prometheus.new("prometheus-dev", "monitoring-dev", 9090),
 # loki: loki.new("loki-dev", "monitoring-dev", 3100),  // Add Loki configuration
}

