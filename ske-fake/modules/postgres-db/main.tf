variable "workspace_identifier" {
  type = string
}

variable "project_identifier" {
  type = string
}

variable "namespace" {
  type = string
}

variable "landing_zone_identifier" {
  type = string
}

variable "enable_audit" {
  type    = bool
  default = false
}

variable "instance_hosts" {
  type        = map(string)
  description = "Write endpoint of the shared instance per landing zone identifier."
}

variable "delay_seconds" {
  type    = number
  default = 12
}


resource "time_sleep" "provisioning" {
  create_duration = "${var.delay_seconds}s"

  triggers = {
    database = local.database
  }
}

locals {
  database = replace("${var.workspace_identifier}_${var.project_identifier}", "-", "_")
  host     = var.instance_hosts[var.landing_zone_identifier]
  instance = split(".", local.host)[0]
}

output "database" {
  value = time_sleep.provisioning.triggers.database
}

output "username" {
  value = local.database
}

output "host" {
  value = local.host
}

output "port" {
  value = 5432
}

output "secret_name" {
  value = "postgres"
}

output "summary" {
  description = "Markdown summary shown in meshPanel after the run."
  value       = <<-EOT
    # PostgreSQL database `${local.database}`

    > This is a **fake** database for the dev environment. Nothing was created on STACKIT or in the cluster.

    Your namespace `${var.namespace}` has a database of its own on the shared PostgreSQL instance
    `${local.instance}` of the landing zone `${var.landing_zone_identifier}`.

    | | |
    |---|---|
    | **Database** | `${local.database}` |
    | **User** (owner) | `${local.database}` |
    | **Host** | `${local.host}` |
    | **Port** | `5432` |
    | **Kubernetes Secret** | `postgres` in `${var.namespace}` |
    | **Audit logging** | ${var.enable_audit ? "on" : "off"} |

    The Secret holds `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME` and
    `SPRING_DATASOURCE_PASSWORD`. A pod reads all three with `envFrom`.

    ## Next step: redeploy

    Running pods do not see a new Secret. Run your pipeline again for this stage, with a push or
    a manual run of the workflow on the stage's branch.
  EOT
}
