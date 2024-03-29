variable "num" {
  type = number
  default = 0
}

variable "text" {
  type = string
  default = "foo"
}

variable "flag" {
  type = bool
  default = false
}

output "num" {
  value = var.num
}

output "text" {
  value = var.text
}

output "flag" {
  value = var.flag
}
