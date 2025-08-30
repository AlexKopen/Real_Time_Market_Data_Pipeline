FROM python:3.10-slim

WORKDIR /app

# --- Install base dependencies ---
RUN apt-get update && \
    apt-get install -y gcc wget curl openjdk-17-jre-headless gnupg \
                       supervisor ca-certificates unzip tar && \
    rm -rf /var/lib/apt/lists/*

# --- Install Python deps ---
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Install Kafka ---
ENV KAFKA_VERSION=3.7.0 \
    SCALA_VERSION=2.13
RUN wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -xvzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && \
    mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && \
    rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

# --- Install ClickHouse ---
RUN wget -qO - https://packages.clickhouse.com/CLICKHOUSE-KEY.GPG | apt-key add - && \
    echo "deb https://packages.clickhouse.com/deb stable main" | tee \
    /etc/apt/sources.list.d/clickhouse.list && \
    apt-get update && \
    apt-get install -y clickhouse-server clickhouse-client && \
    rm -rf /var/lib/apt/lists/*

# --- Install Grafana ---
RUN wget https://dl.grafana.com/oss/release/grafana_11.0.0_amd64.deb && \
    apt-get install -y ./grafana_11.0.0_amd64.deb && \
    rm grafana_11.0.0_amd64.deb

# --- Install Prometheus ---
RUN wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz && \
    tar xvf prometheus-2.53.0.linux-amd64.tar.gz && \
    mv prometheus-2.53.0.linux-amd64 /opt/prometheus && \
    rm prometheus-2.53.0.linux-amd64.tar.gz

# --- Install Blackbox exporter ---
RUN wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.25.0/blackbox_exporter-0.25.0.linux-amd64.tar.gz && \
    tar xvf blackbox_exporter-0.25.0.linux-amd64.tar.gz && \
    mv blackbox_exporter-0.25.0.linux-amd64 /opt/blackbox_exporter && \
    rm blackbox_exporter-0.25.0.linux-amd64.tar.gz

# --- Install Loki & Promtail ---
RUN wget https://github.com/grafana/loki/releases/download/v2.9.4/loki-linux-amd64.zip && \
    unzip loki-linux-amd64.zip && \
    mv loki-linux-amd64 /usr/local/bin/loki && \
    chmod +x /usr/local/bin/loki && \
    rm loki-linux-amd64.zip

RUN wget https://github.com/grafana/loki/releases/download/v2.9.4/promtail-linux-amd64.zip && \
    unzip promtail-linux-amd64.zip && \
    mv promtail-linux-amd64 /usr/local/bin/promtail && \
    chmod +x /usr/local/bin/promtail && \
    rm promtail-linux-amd64.zip

# --- Copy configs and app code ---
COPY . .
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# --- Expose ports (same as compose) ---
EXPOSE 9092 9093 19092 8123 9000 3000 9115 9090 3100 8001

# --- Start everything ---
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
