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
variable "region" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
