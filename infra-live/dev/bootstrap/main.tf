terraform {
  required_version = ">= 1.7, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
  # local backend on purpose — this stack CREATES the remote backend.
}

provider "aws" {
  region = var.region
}

module "s3_backend" {
  source                = "../../../infra-modules/s3_backend"
  region                = var.region
  tf_state_bucket       = var.tf_state_bucket
  tf_lock_table         = var.tf_lock_table
  kops_state_bucket     = var.kops_state_bucket
  oidc_discovery_bucket = var.oidc_discovery_bucket
  tags = {
    Project     = "retail-store-poc"
    Environment = "dev"
    ManagedBy   = "terraform-bootstrap"
  }
}

variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "tf_state_bucket" {
  type    = string
  default = "retail-poc-tfstate-dev-125788629837"
}
variable "tf_lock_table" {
  type    = string
  default = "retail-poc-tflock-dev"
}
variable "kops_state_bucket" {
  type    = string
  default = "retail-poc-kops-dev-125788629837"
}
variable "oidc_discovery_bucket" {
  type    = string
  default = "retail-poc-oidc-dev-125788629837"
}

output "tf_state_bucket" {
  value = module.s3_backend.tf_state_bucket
}
output "tf_lock_table" {
  value = module.s3_backend.tf_lock_table
}
output "kops_state_store" {
  value = module.s3_backend.kops_state_store
}
output "oidc_issuer_url" {
  value = module.s3_backend.oidc_issuer_url
}
