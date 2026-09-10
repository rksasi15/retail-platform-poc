variable "name" {
  type = string
}
variable "deletion_window_in_days" {
  type    = number
  default = 7
}
variable "additional_key_users" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
