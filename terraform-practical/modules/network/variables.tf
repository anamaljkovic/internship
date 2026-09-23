variable "network_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "region" {
  type = string
}

variable "allowed_ssh_ranges" {
  type = list(string)
}

variable "allowed_http_ranges" {
  type = list(string)
}

variable "app_port" {
  type = number
}   