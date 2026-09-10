variable "name" {
  type = string
}
variable "cluster_name" {
  type        = string
  description = "kOps cluster FQDN, used for kubernetes.io/cluster/<name> tags"
}
variable "cidr" {
  type = string
}
variable "azs" {
  type = list(string)
}
variable "nat_gateway_count" {
  type    = number
  default = 2
  validation {
    condition     = var.nat_gateway_count >= 1
    error_message = "Need at least 1 NAT GW."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
