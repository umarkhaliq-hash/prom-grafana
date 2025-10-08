from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics
import psutil
import time
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST
from flask import Response

app = Flask(__name__)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)

# Custom metrics for system monitoring
cpu_usage = Gauge('app_cpu_usage_percent', 'CPU usage percentage')
memory_usage = Gauge('app_memory_usage_bytes', 'Memory usage in bytes')
memory_percent = Gauge('app_memory_usage_percent', 'Memory usage percentage')

@app.route('/')
def home():
    return "Hello from Docker!"

@app.route('/metrics')
def metrics_endpoint():
    # Update system metrics
    cpu_usage.set(psutil.cpu_percent())
    memory_info = psutil.virtual_memory()
    memory_usage.set(memory_info.used)
    memory_percent.set(memory_info.percent)
    
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

