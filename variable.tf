variable "vpc_cidr_block" {
    type = string
}

variable "subnet" {
    type = list(string)
}

variable "gfpassword" {
  type      = string
  sensitive = true
}