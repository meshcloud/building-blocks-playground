variable "display_name" {
  type = string
}

variable "description" {
  type = string
}

variable "readme" {
  type    = string
  default = null
}

variable "symbol" {
  type = string
}

variable "target_type" {
  type    = string
  default = "TENANT_LEVEL"
}

variable "supported_platforms" {
  type = list(object({
    kind = optional(string)
    name = optional(string)
    uuid = optional(string)
  }))
  default = null
}

variable "use_in_landing_zones_only" {
  type    = bool
  default = false
}

variable "dependency_refs" {
  type = list(object({
    kind = string
    uuid = string
  }))
  default = null
}

variable "implementation_path" {
  type        = string
  default     = "ske-fake/modules/fake-service"
  description = "Path of the fake Terraform module in the building-blocks-playground repository."
}

variable "fake_service" {
  type = object({
    service       = string
    delay_seconds = number
    fake_outputs  = optional(map(string), {})
  })
  default     = null
  description = "Inputs for the generic fake-service module. Leave null for a dedicated fake module."
}

variable "inputs" {
  type = map(object({
    display_name           = string
    type                   = string
    assignment_type        = string
    description            = optional(string)
    argument               = optional(string)
    default_value          = optional(string)
    is_environment         = optional(bool)
    updateable_by_consumer = optional(bool)
    condition              = optional(string)
    value_validation_regex = optional(string)

    validation_regex_error_message = optional(string)
  }))
  default = {}
}

variable "outputs" {
  type = map(object({
    display_name    = string
    type            = string
    assignment_type = string
    description     = optional(string)
  }))
  default = {}
}

variable "approval_policies" {
  type    = any
  default = null
}

variable "fake_git_ref" {
  type    = string
  default = "ske-fake"
}

variable "meshstack" {
  type = object({
    owning_workspace_identifier = string
    tags                        = optional(map(list(string)), {})
    runner_ref = optional(object({
      kind = string
      uuid = string
    }))
  })
}

variable "draft" {
  type    = bool
  default = true
}
