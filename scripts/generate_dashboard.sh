#!/bin/bash

# Script to update Prometheus connector UID in PostgreSQL HA dashboard JSON

# Check if agent UID argument is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 <prometheus_agent_uid>"
  exit 1
fi

PROMETHEUS_AGENT_UID="$1"
DASHBOARD_FILE="../grafana-dashboards/postgresql_ha.json"

# Check if the dashboard file exists
if [ ! -f "$DASHBOARD_FILE" ]; then
  echo "Error: Dashboard file $DASHBOARD_FILE not found."
  exit 1
fi

# Create a backup of the original file
cp "$DASHBOARD_FILE" "${DASHBOARD_FILE}.bak"

# Update the Prometheus datasource UID in the JSON file
if command -v jq &> /dev/null; then
  # Use jq to update the datasource UIDs wherever they appear
  jq --arg uid "$PROMETHEUS_AGENT_UID" '
    walk(
      if type == "object" and .datasource != null and .datasource.type == "prometheus" then
        .datasource.uid = $uid
      else
        .
      end
    )
  ' "$DASHBOARD_FILE" > "${DASHBOARD_FILE}.tmp"
  
  if [ $? -eq 0 ]; then
    mv "${DASHBOARD_FILE}.tmp" "$DASHBOARD_FILE"
  else
    echo "Error updating JSON with jq. Check the backup file."
    exit 1
  fi
else
  # Fallback to sed for basic replacement - more precise pattern matching
  sed -i 's/"datasource": {\s*"type": "prometheus",\s*"uid": "[^"]*"/"datasource": {\n            "type": "prometheus",\n            "uid": "'$PROMETHEUS_AGENT_UID'"/g' "$DASHBOARD_FILE"
fi

echo "Updated Prometheus connector UID to $PROMETHEUS_AGENT_UID in $DASHBOARD_FILE"