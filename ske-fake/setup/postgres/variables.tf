variable "workspace" {
  type = string
}

variable "runner_ref" {
  type = object({
    kind = string
    uuid = string
  })
  default = null
}

variable "platform_identifier" {
  type    = string
  default = "ske-fake"
}

variable "stackit_tenant_uuid" {
  type        = string
  description = "meshTenant of the platform's fake STACKIT project, created by the reference architecture."
}

variable "stages" {
  type    = list(string)
  default = ["dev", "prod"]
}

variable "hub_git_ref" {
  type    = string
  default = "97246e3c3d1fc0ac835a4574dd13667248eb6060"
}

variable "fake_git_ref" {
  type    = string
  default = "ske-fake"
}
