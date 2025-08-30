FROM openjdk:17-slim

WORKDIR /app

# --- Install base dependencies ---
    RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv gcc wget curl supervisor unzip tar && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# --- Install Python deps ---
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Install Kafka ---
ENV KAFKA_VERSION=3.7.0
ENV SCALA_VERSION=2.13    
RUN wget -qO- "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" | tar xz -C /opt && \
    mv /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka

# Install prerequisite packages
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg

# Download the ClickHouse GPG key and store it in the keyring
RUN curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg

# Get the system architecture
RUN ARCH=$(dpkg --print-architecture) && echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list

# Update apt package lists
RUN apt-get update
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y clickhouse-server clickhouse-client

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
