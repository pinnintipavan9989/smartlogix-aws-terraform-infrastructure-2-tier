#!/bin/bash

echo "===== EC2 METADATA ====="
curl -s http://169.254.169.254/latest/meta-data/

echo ""
echo "===== INSTANCE ID ====="
curl -s http://169.254.169.254/latest/meta-data/instance-id

echo ""
echo "===== CPU & MEMORY ====="
echo "CPU Load:"
uptime
echo ""
echo "Memory Usage:"
free -h

echo ""
echo "===== DISK USAGE ====="
df -h

echo ""
echo "===== NETWORK ====="
echo "Private IP:"
hostname -I
echo ""
echo "Open Ports:"
ss -tulnp

echo ""
echo "===== PROCESS STATUS ====="
top -bn1 | head

#sudo nano /opt/system_info.sh
#sudo chmod +x /opt/system_info.sh
#sudo /opt/system_info.sh

#sudo sh -c "/opt/system_info.sh > /opt/system_report.txt"
#ls -l /opt/system_report.txt
#cat /opt/system_report.txt
#aws s3 cp /opt/system_report.txt s3://pavan-624615-dev-backups/reports/system_report.txt

