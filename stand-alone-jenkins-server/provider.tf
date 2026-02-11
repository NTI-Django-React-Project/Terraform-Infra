terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

    backend "s3" {
    bucket         = "gig-route-terraform-bucket"
    key            = "tfstate-dir/stand-alone-terraform.tfstate" # path inside bucket
    region         = "eu-north-1"
    dynamodb_table = "gig-route-terraform-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
