variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "name_prefix" {
  type    = string
  default = "retail-poc-dev"
}
variable "cluster_name" {
  type        = string
  description = "kOps cluster FQDN, e.g. dev.retail.internal"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}
variable "nat_gateway_count" {
  type    = number
  default = 2
}
variable "private_zone_name" {
  type    = string
  default = "dev.retail.internal"
}
variable "public_zone_id" {
  type    = string
  default = "" # empty = no public domain (PoC path)
}
variable "tf_state_bucket" {
  type = string
}
variable "tf_lock_table" {
  type = string
}
variable "kops_state_bucket" {
  type = string
}
variable "oidc_discovery_bucket" {
  type = string
}
variable "create_irsa" {
  type    = bool
  default = false
}
