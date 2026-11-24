variable "namespace" {
  type = string
}

variable "kube_host" {
  type = string
}

variable "repository_owner" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "stage" {
  type    = string
  default = "dev"
}

variable "app_hostname" {
  type = string
}

variable "forgejo_host" {
  type = string
}

variable "additional_kubernetes_secrets" {
  type    = map(string)
  default = {}
}

variable "pipeline_seconds" {
  type    = number
  default = 20
}

resource "time_sleep" "pipeline" {
  create_duration = "${var.pipeline_seconds}s"

  triggers = {
    run = plantimestamp()
  }
}

locals {
  app_url        = "https://${var.app_hostname}"
  repository_url = "${trimsuffix(var.forgejo_host, "/")}/${var.repository_owner}/${var.repository_name}"
  actions_url    = "${local.repository_url}/actions?workflow=pipeline.yaml"
}

output "app_link" {
  value = local.app_url
}

output "actions_url" {
  value = local.actions_url
}

output "summary" {
  description = "Markdown summary shown on the building block."
  value       = <<-EOT
    # Forgejo Connector: **${var.stage}**

    > This is a **fake** connector for the dev environment. The pipeline "ran" for ${var.pipeline_seconds} s at ${time_sleep.pipeline.triggers.run}, and nothing was deployed.

    The `${var.stage}` branch of [${var.repository_owner}/${var.repository_name}](${local.repository_url}) deploys
    to the namespace `${var.namespace}` on `${var.kube_host}`.

    | Property | Value |
    |----------|-------|
    | **Application** | [${local.app_url}](${local.app_url}) |
    | **Pipeline** | [`pipeline.yaml` in Forgejo Actions](${local.actions_url}) |
    | **Service Account** | `forgejo-actions`, `edit` on the namespace |

    ## Forgejo Actions secrets and variables

    | Name | Kind | Holds |
    |------|------|-------|
    | `KUBECONFIG_${upper(var.stage)}` | secret | kubeconfig of the service account |
    | `K8S_NAMESPACE_${upper(var.stage)}` | variable | `${var.namespace}` |
    | `APP_HOSTNAME_${upper(var.stage)}` | variable | `${var.app_hostname}` |
    %{~if length(var.additional_kubernetes_secrets) > 0}

    ## Kubernetes secrets in the namespace

    | Secret | Filled from the Vault secret |
    |--------|------------------------------|
    %{~for name, path in var.additional_kubernetes_secrets}
    | `${name}` | `${path}` |
    %{~endfor}
    %{~endif}
  EOT
}
