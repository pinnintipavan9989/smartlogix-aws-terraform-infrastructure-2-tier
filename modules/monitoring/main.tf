# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name         = var.sns_name
  display_name = "${var.project_prefix}-${var.env}-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
}

# CloudWatch Log Groups for API and DB slow query (these will be used by the agents and RDS)
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/smartlogix/api"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "db_slow_query" {
  name              = "/aws/smartlogix/db/slowquery"
  retention_in_days = 30
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_prefix}-${var.env}-rds-cpu-high"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_description   = "Triggers when RDS CPU usage exceeds 80%"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}


# API latency alarm (uses custom metric namespace SmartLogiX/API - the app or agent should push metric 'LatencyMs')
resource "aws_cloudwatch_metric_alarm" "api_high_latency" {
  alarm_name          = "${var.project_prefix}-${var.env}-api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "LatencyMs"
  namespace           = "SmartLogiX/API"
  period              = 60
  statistic           = "Average"
  threshold           = 250
  alarm_description   = "API latency greater than 250ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# DB slow query alarm (expect your RDS slow query exporter to publish metric DBSlowQueryMs to namespace SmartLogiX/DB)
resource "aws_cloudwatch_metric_alarm" "db_slow_query" {
  alarm_name          = "${var.project_prefix}-${var.env}-db-slow-query"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DBSlowQueryMs"
  namespace           = "SmartLogiX/DB"
  period              = 60
  statistic           = "Average"
  threshold           = 500
  alarm_description   = "DB slow query time greater than 500ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Disk IOPS & Memory metrics - these will rely on CloudWatch agent (we create dashboards or just note log groups)
resource "aws_cloudwatch_dashboard" "smartlogix" {
  dashboard_name = "${var.project_prefix}-${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type"   = "metric"
        "x"      = 0
        "y"      = 0
        "width"  = 12
        "height" = 6
        "properties" = {
          "region"  = var.aws_region
          "title"   = "Memory Used (%)"
          "view"    = "timeSeries"
          "period"  = 60
          "stacked" = false
          "metrics" = [
            ["CWAgent", "mem_used_percent", "InstanceId", var.api_instance_id]
          ]
        }
      },
      {
        "type"   = "alarm"
        "x"      = 0
        "y"      = 6
        "width"  = 12
        "height" = 6
        "properties" = {
          "alarms" = [
            aws_cloudwatch_metric_alarm.rds_cpu.arn,
            aws_cloudwatch_metric_alarm.api_high_latency.arn,
            aws_cloudwatch_metric_alarm.db_slow_query.arn
          ]
        }
      }
    ]
  })
}
