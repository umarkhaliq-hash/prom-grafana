local grafana = import "../../lib/grafana.libsonnet";
local prometheus = import "../../lib/prometheus.libsonnet";

{
   namespace: {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: { name: "monitoring-prod" },
  },


  grafana: grafana.new("grafana-prod", "monitoring-prod", 3000),
  prometheus: prometheus.new("prometheus-prod", "monitoring-prod", 9090),
}

