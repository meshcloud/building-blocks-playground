variable "workspace_identifier" {
  type = string
}

variable "project_identifier" {
  type = string
}

variable "landing_zone_identifier" {
  type    = string
  default = ""
}

variable "delay_seconds" {
  type    = number
  default = 5
}

locals {
  namespace = substr(lower("${var.workspace_identifier}-${var.project_identifier}"), 0, 63)
}

resource "time_sleep" "replication" {
  create_duration = "${var.delay_seconds}s"

  triggers = {
    namespace = local.namespace
  }
}

output "namespace" {
  description = "Name of the Kubernetes namespace, which becomes the tenant's platform tenant ID."
  value       = time_sleep.replication.triggers.namespace
}

output "summary" {
  description = "Markdown summary shown on the building block."
  value       = <<-EOT
    # Kubernetes Namespace `${local.namespace}`

    > This is a **fake** SKE namespace for the dev environment. No cluster was touched.

    | Property | Value |
    |----------|-------|
    | **Namespace** | `${local.namespace}` |
    | **Landing Zone** | `${var.landing_zone_identifier}` |
  EOT
}
