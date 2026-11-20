output "backend_config_snippet" {
  description = "Copy and paste this snippet into environments/prod/backend.tf"
  value       = <<EOF
terraform {
  backend "s3" {
    bucket         = "${aws_s3_bucket.terraform_state.id}"
    key            = "prod/terraform.tfstate"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    encrypt        = true
  }
}
EOF
}