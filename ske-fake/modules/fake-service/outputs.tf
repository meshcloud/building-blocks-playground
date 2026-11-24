output "summary" {
  description = "Markdown summary shown on the building block."
  value = join("\n", concat(
    [
      "# ${var.service}",
      "",
      "> This is a **fake** of ${var.service} for the dev environment. Nothing was provisioned on STACKIT.",
      "",
      "| Output | Value |",
      "|--------|-------|",
    ],
    [for name, value in local.values : "| `${name}` | `${value}` |"],
  ))
}

output "project_id" {
  value = lookup(local.values, "project_id", null)
}

output "project_url" {
  value = lookup(local.values, "project_url", null)
}

output "service_account_email" {
  value = lookup(local.values, "service_account_email", null)
}

output "service_account_id" {
  value = lookup(local.values, "service_account_id", null)
}

output "instance_id" {
  value = lookup(local.values, "instance_id", null)
}

output "instance_url" {
  value = lookup(local.values, "instance_url", null)
}

output "forgejo_organization" {
  value = lookup(local.values, "forgejo_organization", null)
}

output "kube_host" {
  value = lookup(local.values, "kube_host", null)
}

output "cluster_name" {
  value = lookup(local.values, "cluster_name", null)
}

output "haproxy_lb_ip" {
  value = lookup(local.values, "haproxy_lb_ip", null)
}

output "dns_zone_name" {
  value = lookup(local.values, "dns_zone_name", null)
}

output "model_name" {
  value = lookup(local.values, "model_name", null)
}

output "api_url" {
  value = lookup(local.values, "api_url", null)
}

output "registry_host" {
  value = lookup(local.values, "registry_host", null)
}

output "registry_name" {
  value = lookup(local.values, "registry_name", null)
}

output "registry_url" {
  value = lookup(local.values, "registry_url", null)
}

output "registry_robot_url" {
  value = lookup(local.values, "registry_robot_url", null)
}

output "host" {
  value = lookup(local.values, "host", null)
}
