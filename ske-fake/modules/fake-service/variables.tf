variable "service" {
  type        = string
  description = "Name of the STACKIT service this building block pretends to provision."
}

variable "delay_seconds" {
  type        = number
  default     = 5
  description = "How long the first run waits, to feel like provisioning on STACKIT."
}

variable "fake_outputs" {
  type        = map(string)
  default     = {}
  description = "Output values by output name. `{uuid}` and `{suffix}` are replaced with values generated once per building block."
}
