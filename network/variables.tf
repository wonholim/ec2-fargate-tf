variable "project_name" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = "Vardy"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "az_count" {
  type    = string
  default = 4
}

variable "allow_all_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
