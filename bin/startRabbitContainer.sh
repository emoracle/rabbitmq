#!/bin/bash

# Check if the RabbitMQ data volume exists
if docker volume ls | grep -q rabbitmq_data; then
    echo "Volume rabbitmq_data already exists."| tee -a $LOG_FILE
else
    echo "Volume rabbitmq_data does not exist, creating now."| tee -a $LOG_FILE
    docker volume create rabbitmq_data| tee -a $LOG_FILE
fi

# Starten met SSL

CONTAINER_NAME="rabbitmq"
RABBITMQ_CONFIG_PATH="/home/edwin/rabbitmq/conf/rabbitmq.conf"
RABBITMQ_PLUGINS_PATH="/home/edwin/rabbitmq/conf/enabled_plugins"
CA_CERT_PATH="/home/edwin/rabbitmq/certs/ca_certificate.pem"
SERVER_CERT_PATH="/home/edwin/rabbitmq/certs/server_certificate.pem"
SERVER_KEY_PATH="/home/edwin/rabbitmq/certs/server_key.pem"
RABBITMQ_DEFAULT_USER="user"
RABBITMQ_DEFAULT_PASS="password"
SSL_PORT=5671
MANAGEMENT_PORT=15672
LOG_FILE="/home/edwin/rabbitmq/logs/rabbitmq_docker.log"

# Ensure the SSL certificate files have secure permissions (Note for users)
echo "Ensure SSL certificate files have secure permissions set."

# Check if the RabbitMQ configuration file exists
if [ ! -f "$RABBITMQ_CONFIG_PATH" ]; then
    echo "RabbitMQ configuration file not found at $RABBITMQ_CONFIG_PATH" | tee -a $LOG_FILE
    exit 1
fi

# Check if the SSL certificate files exist
if [ ! -f "$CA_CERT_PATH" ] || [ ! -f "$SERVER_CERT_PATH" ] || [ ! -f "$SERVER_KEY_PATH" ]; then
    echo "One or more SSL certificate files not found." | tee -a $LOG_FILE
    exit 1
fi

# Check if the SSL port is available
if lsof -i:$SSL_PORT | grep LISTEN; then
    echo "SSL port $SSL_PORT is already in use. Please choose another port." | tee -a $LOG_FILE
    exit 1
fi

# Check if the Management port is available
if lsof -i:$MANAGEMENT_PORT | grep LISTEN; then
    echo "Management port $MANAGEMENT_PORT is already in use. Please choose another port." | tee -a $LOG_FILE
    exit 1
fi

# Check if the container exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Container $CONTAINER_NAME exists, stopping and removing it..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    echo "Container $CONTAINER_NAME has been removed."
fi

# Run RabbitMQ container with SSL configuration and log output
{
    echo "Starting RabbitMQ with SSL..."
    docker run -d \
      --name $CONTAINER_NAME \
      --hostname konijntje \
      -p $SSL_PORT:5671 \
      -p $MANAGEMENT_PORT:15672 \
      -v "$RABBITMQ_CONFIG_PATH:/etc/rabbitmq/rabbitmq.conf" \
      -v "$RABBITMQ_PLUGINS_PATH:/etc/rabbitmq/enabled_plugins" \
      -v "$CA_CERT_PATH:/etc/rabbitmq/ssl/ca_certificate.pem" \
      -v "$SERVER_CERT_PATH:/etc/rabbitmq/ssl/server_certificate.pem" \
      -v "$SERVER_KEY_PATH:/etc/rabbitmq/ssl/server_key.pem" \
      -v rabbitmq_data:/var/lib/rabbitmq \
      -e RABBITMQ_DEFAULT_USER="$RABBITMQ_DEFAULT_USER" \
      -e RABBITMQ_DEFAULT_PASS="$RABBITMQ_DEFAULT_PASS" \
      rabbitmq:management
} 2>&1 | tee -a $LOG_FILE

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "RabbitMQ with SSL is starting up... Logs can be found in $LOG_FILE" | tee -a $LOG_FILE
else
    echo "Failed to start RabbitMQ with SSL. Check logs in $LOG_FILE for details." | tee -a $LOG_FILE
fi

