#!/bin/bash
set -euo pipefail

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx python3 python3-pip wget unzip default-mysql-client awscli

pip3 install flask pymysql

############################################
# FIXED: Python indentation + template vars escaped
############################################
cat > /opt/smartlogix_app.py <<'PY'
from flask import Flask, jsonify, request
import pymysql
import os

app = Flask(__name__)

def get_db_connection():
    return pymysql.connect(
        host="${db_endpoint}",
        user="${db_username}",
        password="${db_password}",
        database="smartlogix",
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/')
def index():
    return "SmartLogiX Tracking API Live"

@app.route('/shipments', methods=['GET'])
def get_shipments():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, shipment_id, origin, destination, status, created_at FROM Shipments ORDER BY created_at DESC")
            rows = cursor.fetchall()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/statushistory', methods=['GET'])
def get_status_history():
    shipment_id = request.args.get('shipment_id')
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            if shipment_id:
                cursor.execute("SELECT id, shipment_id, status, changed_at FROM StatusHistory WHERE shipment_id=%s ORDER BY changed_at DESC", (shipment_id,))
            else:
                cursor.execute("SELECT id, shipment_id, status, changed_at FROM StatusHistory ORDER BY changed_at DESC")
            rows = cursor.fetchall()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PY

############################################
# Systemd service
############################################
cat > /etc/systemd/system/smartlogix.service <<'SU'
[Unit]
Description=SmartLogiX Flask App
After=network.target

[Service]
User=root
ExecStart=/usr/bin/python3 /opt/smartlogix_app.py
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SU

systemctl daemon-reload
systemctl enable smartlogix
systemctl restart smartlogix || true

############################################
# Nginx reverse proxy
############################################
cat > /etc/nginx/sites-available/smartlogix <<'NG'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NG

ln -sf /etc/nginx/sites-available/smartlogix /etc/nginx/sites-enabled/smartlogix
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

############################################
# MySQL DB/Tables Auto-Creation
############################################

MAX_RETRIES=10
SLEEP=6
i=0

until mysql -h "${db_endpoint}" -u"${db_username}" -p"${db_password}" -e "SELECT 1" >/dev/null 2>&1 || [ $i -ge $MAX_RETRIES ]; do
  i=$((i+1))
  sleep $SLEEP
done

if mysql -h "${db_endpoint}" -u"${db_username}" -p"${db_password}" -e "SELECT 1" >/dev/null 2>&1; then

mysql -h "${db_endpoint}" -u"${db_username}" -p"${db_password}" <<'SQL'
CREATE DATABASE IF NOT EXISTS smartlogix;
USE smartlogix;

CREATE TABLE IF NOT EXISTS Shipments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id VARCHAR(64),
  origin VARCHAR(128),
  destination VARCHAR(128),
  status VARCHAR(64),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS StatusHistory (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id VARCHAR(64),
  status VARCHAR(64),
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

############################################
# FIXED: Escaped ${ROWS} so Terraform does NOT interpolate it
############################################
ROWS=$(mysql -s -N -h "${db_endpoint}" -u"${db_username}" -p"${db_password}" -e "SELECT COUNT(*) FROM smartlogix.Shipments;" 2>/dev/null || echo "0")

if [ "${ROWS}" = "" ] || [ "${ROWS}" -eq 0 ]; then
mysql -h "${db_endpoint}" -u"${db_username}" -p"${db_password}" <<'SQL'
USE smartlogix;
INSERT INTO Shipments (shipment_id, origin, destination, status) VALUES
('SHP-1001','Delhi','Mumbai','In Transit'),
('SHP-1002','Bengaluru','Hyderabad','Delivered'),
('SHP-1003','Chennai','Kolkata','Pending');

INSERT INTO StatusHistory (shipment_id, status) VALUES
('SHP-1001','Picked Up'),
('SHP-1001','In Transit');
SQL
fi

else
  echo "WARNING: Could not reach RDS within timeout - DB/Tables creation skipped"
fi

############################################
# CloudWatch Agent Install
############################################

CWA_DEB_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
wget -q -O /tmp/amazon-cloudwatch-agent.deb "${CWA_DEB_URL}" || true

if [ -f /tmp/amazon-cloudwatch-agent.deb ]; then
  dpkg -i /tmp/amazon-cloudwatch-agent.deb || true
  apt-get install -f -y || true
fi

############################################
# FIXED: InstanceId now uses AWS runtime variable {instance_id}
############################################
cat > /opt/amazon-cloudwatch-agent.json <<'JSON'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/smartlogix/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/smartlogix/nginx/error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/smartlogix/syslog",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "SmartLogiX/EC2",
    "append_dimensions": {
      "InstanceId": "{instance_id}"
    },
    "metrics_collected": {
      "disk": {
        "measurement": [
          { "name": "used_percent" }
        ],
        "metrics_collection_interval": 60,
        "resources": [ "*" ]
      },
      "mem": {
        "measurement": [ "mem_used_percent" ],
        "metrics_collection_interval": 60
      },
      "net": {
        "measurement": [ "bytes_sent", "bytes_recv" ],
        "metrics_collection_interval": 60
      }
    }
  }
}
JSON

############################################
# Start CloudWatch Agent
############################################
if command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl >/dev/null 2>&1; then
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c file:/opt/amazon-cloudwatch-agent.json -s || true
fi

############################################
# Permissions
############################################
chown root:root /opt/smartlogix_app.py
chmod 644 /opt/smartlogix_app.py

systemctl restart smartlogix || true
systemctl restart nginx || true
