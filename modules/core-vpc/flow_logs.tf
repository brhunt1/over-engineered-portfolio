# This file provisions the IAM role and policy for VPC Flow Logs. It also provisions the log group, KMS key and log stream in CloudWatch Logs.

# KMS Key

resource "aws_kms_key" "flow_logs" {
  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-flow-logs-kms"
  }
}

# CloudWatch Log Group

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = {
    Name = "${var.project_name}-flow-logs-group"
  }
}

# IAM Role

resource "aws_iam_role" "flow_logs" {
  name               = "${var.project_name}-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.project_name}-flow-logs-policy"
  role   = aws_iam_role.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.flow_logs.arn
      }
    ]
  })
}

# VPC flow log resource

resource "aws_flow_log" "flow_logs" {
  log_destination      = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}