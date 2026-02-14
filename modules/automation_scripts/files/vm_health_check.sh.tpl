#!/bin/bash
set -e

REPORT="/tmp/smartlogix_vm_report_$(date +%Y%m%d%H%M%S).txt"

{
echo "================ SmartLogiX VM Health Report ================"
echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%SZ")"
echo ""
echo "Instance Metadata:"
curl -s http://169.254.169.254/latest/dynamic/instance-identity/document || echo "Metadata Unavailable"

echo ""
echo "---------------- Open TCP/UDP Ports ----------------"
ss -tuln || echo "Port Scan Failed"

echo ""
echo "---------------- Memory Stats ----------------"
free -m || echo "Memory Command Failed"

echo ""
echo "---------------- Disk Usage ----------------"
df -h || echo "Disk Command Failed"

API_URL="http://localhost:8080/"

# API Health Check - do not change %% → Terraform requires escaping
HTTP_CODE=$(curl -s -o /tmp/_api_out -w "%%{http_code}" "$API_URL" || echo "000")

echo ""
echo "---------------- API Health Check ----------------"
echo "API URL: $API_URL"
echo "HTTP Response Code: $HTTP_CODE"
cat /tmp/_api_out || echo "API Response Fetch Failed"

} > "$REPORT"

# Upload to S3
aws s3 cp "$REPORT" "s3://${backup_bucket}/${project_prefix}/${env}/reports/$(basename "$REPORT")" \
  && echo "Report successfully uploaded to S3" \
  || echo "Upload to S3 failed"

echo "Report generated at: $REPORT"
