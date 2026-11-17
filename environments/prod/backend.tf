# S3 and DynamoDB remote state configuration for Terraform

terraform{
  backend "s3" {
    bucket         = "over-engineered-portfolio-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}