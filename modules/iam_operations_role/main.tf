# Role for human operations (view logs, reboot, read secret) + an EC2 instance role for automation
resource "aws_iam_role" "operations_analyst" {
  name = "${var.project_prefix}-${var.env}-operations-analyst"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" } # you can replace with specific principals if needed
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "operations_policy" {
  name        = "${var.project_prefix}-${var.env}-ops-policy"
  description = "Allow view logs, reboot instances, read secrets; but deny stop/terminate"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:RebootInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Effect = "Deny",
        Action = [
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:DeleteKeyPair"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ops" {
  role       = aws_iam_role.operations_analyst.name
  policy_arn = aws_iam_policy.operations_policy.arn
}

# Instance role for EC2 to upload backups/reports and push metrics
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_prefix}-${var.env}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ec2_policy" {
  name = "${var.project_prefix}-${var.env}-ec2-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.backup_bucket_name}",
          "arn:aws:s3:::${var.backup_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.ec2_instance_profile_name
  role = aws_iam_role.ec2_role.name
}


