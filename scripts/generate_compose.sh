#!/bin/bash

# Configuration
BASE_PORT=5555
OUTPUT_FILE="docker-compose.yml"

cat > "$OUTPUT_FILE" <<EOF
services:
EOF

# Find all dev branches
find branches/ -maxdepth 1 -type d -name 'dev-*' | while read -r dir; do
  BRANCH_NAME=$(basename "$dir")
  PORT=$((BASE_PORT++))
  SERVICE_NAME="irc-${BRANCH_NAME#dev-}"
  
  cat >> "$OUTPUT_FILE" <<EOF
  $SERVICE_NAME:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        FOLDER_NAME: $BRANCH_NAME
        PORT: "$PORT"
    container_name: $SERVICE_NAME
    ports:
      - "$PORT:$PORT"
EOF
done