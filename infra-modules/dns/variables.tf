variable "private_zone_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_zone_id" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
