terraform {
  required_version = ">= 1.7, < 2.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "retail-store-poc"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "devops"
    }
  }
}
