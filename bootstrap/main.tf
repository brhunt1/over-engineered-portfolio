terraform {
    required_version = ">= 1.6.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region

    default_tags{
        tags = {
        Environment = "bootstrap"
        ManagedBy   = "Terraform"
        Project    = var.project_name
        }
    }
}

# S3 Bucket for Terraform State

resource "aws_s3_bucket" "terraform_state" {
    bucket = "${var.project_name}-terraform-state"
    force_destroy = false

    lifecycle{
        prevent_destroy = true
    }
}

# Versioning for state history & recovery

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

# AES-256 server-side encryption

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

# block all public access

resource "aws_s3_bucket_public_access_block" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# DynamoDB Table for Terraform State Locking

resource "aws_dynamodb_table" "terraform_locks" {
    name         = "${var.project_name}-terraform-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    point_in_time_recovery {
        enabled = true
    }

    server_side_encryption {
        enabled = true
    }
}