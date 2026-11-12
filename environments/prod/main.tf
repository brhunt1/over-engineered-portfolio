# Root module 


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
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "Terraform"
      Project     = "over-engineered-portfolio"
    }
  }
}

module "core_vpc" {
  source = "../../modules/core-vpc"

  project_name            = "over-engineered-portfolio"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = ["us-west-2a", "us-west-2b"]
  single_nat_gateway      = true
}