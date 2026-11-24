variable "workspace_identifier" {
  type = string
}

variable "workspace_members" {
  type    = any
  default = []
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = ""
}

variable "private" {
  type    = bool
  default = true
}

variable "clone_addr" {
  type    = string
  default = "null"
}

variable "default_branch" {
  type    = string
  default = "main"
}

variable "action_variables" {
  type    = map(string)
  default = {}
}

variable "extra_action_variables" {
  type    = map(string)
  default = {}
}

variable "forgejo_base_url" {
  type = string
}

variable "forgejo_organization" {
  type = string
}

variable "delay_seconds" {
  type    = number
  default = 5
}

resource "random_integer" "repository_id" {
  min = 100
  max = 99999
}

resource "time_sleep" "provisioning" {
  create_duration = "${var.delay_seconds}s"

  triggers = {
    repository_id = random_integer.repository_id.result
  }
}

locals {
  base_url         = trimsuffix(var.forgejo_base_url, "/")
  host             = replace(local.base_url, "/^https?:\\/\\//", "")
  html_url         = "${local.base_url}/${var.forgejo_organization}/${var.name}"
  clone_url        = "${local.html_url}.git"
  ssh_url          = "git@${local.host}:${var.forgejo_organization}/${var.name}.git"
  have_clone_addr  = var.clone_addr != "" && var.clone_addr != "null"
  action_variables = merge(var.action_variables, var.extra_action_variables)
  members = [
    for member in var.workspace_members : {
      email = try(member.email, "")
      roles = join(", ", try(member.roles, []))
      team  = contains(try(member.roles, []), "Workspace Owner") ? "admins" : contains(try(member.roles, []), "Workspace Manager") ? "writers" : "readers"
    }
  ]
}

output "repository_id" {
  value = tonumber(time_sleep.provisioning.triggers.repository_id)
}

output "repository_owner" {
  value = var.forgejo_organization
}

output "repository_name" {
  value = var.name
}

output "repository_html_url" {
  value = local.html_url
}

output "repository_clone_url" {
  value = local.clone_url
}

output "repository_ssh_url" {
  value = local.ssh_url
}

output "summary" {
  description = "Markdown summary shown on the building block."
  value       = <<-EOT
    # ✅ Git Repository Created

    > This is a **fake** STACKIT Git repository for the dev environment. The links do not resolve.

    **${var.name}** is ready on STACKIT Git Forgejo.

    ## Repository Details

    - **Name**: ${var.name}
    - **Owner**: ${var.forgejo_organization}
    - **Visibility**: ${var.private ? "private" : "public"}
    - **URL**: ${local.html_url}
    - **Clone URL**: `${local.clone_url}`
    %{~if local.have_clone_addr}
    - **Initialized from**: `${var.clone_addr}`
    %{~endif}

    ## Actions Variables

    | Name | Value |
    |------|-------|
    %{~for name, value in local.action_variables}
    | `${name}` | `${value}` |
    %{~endfor}

    ## Workspace Member Access

    | workspace member | role | team |
    |------------------|------|------|
    %{~for m in local.members}
    | `${m.email}` | `${m.roles}` | `${m.team}` |
    %{~endfor}
  EOT
}
