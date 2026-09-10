variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
}
variable "route53_zone_arns" {
  type    = list(string)
  default = []
}
variable "kms_key_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
