output "ske_project_url" {
  description = "Deep link to the STACKIT project the SKE cluster and its assets run in."
  value       = "https://portal.stackit.cloud/dashboard?project=${local.stackit_project_id}"
}

output "summary" {
  description = "Summary of the platform, as the nested building block reports it."
  value       = try(jsondecode(meshstack_building_block.platform.status.outputs["summary"].value), "")
}
