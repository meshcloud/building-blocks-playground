locals {
  runner_ref = var.runner_ref.uuid == null ? null : var.runner_ref

  tenant_ref = { kind = "meshTenant", uuid = var.tenant_uuid }

  service_account_email = var.automation_identity.service_account_email

  hub_symbol = "https://raw.githubusercontent.com/meshcloud/meshstack-hub/${var.hub.git_ref}/modules"

  platform_meshstack   = { owning_workspace_identifier = var.workspace, tags = var.tags.building_block, runner_ref = local.runner_ref }
  starterkit_meshstack = { owning_workspace_identifier = var.workspace, tags = var.tags.starterkit_building_block, runner_ref = local.runner_ref }

  stackit_platforms  = [{ name = "STACKIT" }]
  platform_type_name = "SKE-FAKE"
  fake_platforms     = [{ name = local.platform_type_name }]

  location_name = var.use_global_location ? "global" : meshstack_location.this[0].metadata.name

  stage_names = { dev = "Development", prod = "Production" }

  landing_zones = {
    for stage, cfg in var.stages : stage => {
      name         = "${var.platform_identifier}-namespace-${stage}"
      display_name = "SKE Kubernetes Namespace – ${lookup(local.stage_names, stage, title(stage))}"
      description  = "Landing zone for ${lower(lookup(local.stage_names, stage, stage))} workloads."
      tags         = cfg.landingzone
    }
  }

  stage_project_tags = {
    for stage, cfg in var.stages : stage => merge(var.tags.starterkit_project, cfg.project)
  }
}

resource "meshstack_location" "this" {
  count = var.use_global_location ? 0 : 1

  metadata = {
    name               = var.platform_identifier
    owned_by_workspace = var.workspace
  }

  spec = {
    display_name = var.platform_identifier
    description  = "Fake STACKIT SKE location created by the fake STACKIT Kubernetes Platform."
  }
}

resource "meshstack_building_block" "platform_federation" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [var.automation_identity.building_block_ref]
    building_block_definition_version_ref = var.service_account_federation_bbd_version_ref
    display_name                          = "Automation Identity Federation"
    target_ref                            = local.tenant_ref

    inputs = {
      service_account_email = { value = jsonencode(local.service_account_email) }
      federated_building_block_definitions = {
        value = jsonencode(jsonencode(concat(
          [
            module.cluster_integration.building_block_definition.uuid,
            module.git_integration.building_block_definition.uuid,
            module.container_registry_integration.building_block_definition.uuid,
          ],
          var.ai_model == null ? [] : [module.ai_llm_integration[0].building_block_definition.uuid],
          [
            module.secrets_manager_integration.building_block_definition.uuid,
            module.dns_integration.building_block_definition.uuid,
          ],
          sort([for ref in var.additional_federated_building_block_definitions : ref.uuid]),
        )))
      }
    }
  }
}
