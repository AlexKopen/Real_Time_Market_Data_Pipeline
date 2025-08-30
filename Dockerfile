# Start from Docker-in-Docker image
FROM docker:27.3.1-dind

# Install docker-compose (plugin version)
RUN apk add --no-cache docker-cli-compose bash

# Set working directory
WORKDIR /app

# Copy your docker-compose.yml (and optional env files)
COPY . .

# Run docker-compose when the container starts
CMD ["sh", "-c", "docker compose up -d --build && tail -f /dev/null"]
