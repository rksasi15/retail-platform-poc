# Populated after `make bootstrap`. Values MUST match infra-live/dev/bootstrap outputs.
terraform {
  backend "s3" {
    bucket         = "retail-poc-tfstate-dev-125788629837" # <- from bootstrap
    key            = "dev/foundations.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "retail-poc-tflock-dev"
    encrypt        = true
  }
}
