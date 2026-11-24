variable "workspace" {
  type        = string
  description = "meshStack workspace that owns the fake platform and every definition."
}

variable "payment_method" {
  type        = string
  description = "Payment method of the platform's meshProject."
}

variable "runner_ref" {
  type = object({
    kind = string
    uuid = string
  })
  default     = null
  description = "Building block runner of every fake definition; null uses the default runner."
}

variable "platform_identifier" {
  type    = string
  default = "ske-fake"
}

variable "phase2_completed" {
  type    = bool
  default = false
}

variable "hub_git_ref" {
  type        = string
  default     = "97246e3c3d1fc0ac835a4574dd13667248eb6060"
  description = "meshstack-hub commit the reference architecture and the starter kit come from."
}

variable "fake_git_ref" {
  type    = string
  default = "ske-fake"
}

variable "tags" {
  type = object({
    landingzone        = map(list(string))
    project            = map(list(string))
    starterkit_project = map(list(string))
    stages = map(object({
      landingzone = map(list(string))
      project     = map(list(string))
    }))
  })
  description = "Tags the environment requires on the platform's landing zones and projects."
}

variable "project_owner_tag_key" {
  type    = string
  default = null
}

variable "project_identifier" {
  type        = string
  default     = null
  description = "Identifier of the platform's meshProject, for environments whose identifier pattern rejects `<platform identifier>-ske`."
}
