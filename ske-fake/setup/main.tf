locals {
  meshstack = { owning_workspace_identifier = var.workspace, tags = {}, runner_ref = var.runner_ref }

  hub_symbol = "https://raw.githubusercontent.com/meshcloud/meshstack-hub/${var.hub_git_ref}/modules"

  stackit_platforms = [{ name = "STACKIT" }]

}

resource "meshstack_platform_type" "ske_fake" {
  metadata = {
    name               = "SKE-FAKE"
    owned_by_workspace = var.workspace
  }

  spec = {
    display_name     = "STACKIT Kubernetes Engine (Fake)"
    default_endpoint = "https://api.ske.eu01.fake.invalid"
    icon             = "data:image/svg+xml;base64,${filebase64("${path.module}/ske-logo.svg")}"
  }
}

resource "meshstack_platform" "stackit_fake" {
  metadata = {
    name               = "stackit-fake"
    owned_by_workspace = var.workspace
  }

  spec = {
    display_name      = "STACKIT (Fake)"
    description       = "Fake STACKIT organization for the dev environment. A tenant is a STACKIT project that does not exist."
    endpoint          = "https://portal.stackit.cloud"
    documentation_url = "https://github.com/meshcloud/building-blocks-playground/tree/${var.fake_git_ref}/ske-fake"

    location_ref = { name = "global" }

    availability = {
      publication_state        = "PUBLISHED"
      restriction              = "PUBLIC"
      restricted_to_workspaces = []
    }

    contributing_workspaces = []

    config = {
      custom = {
        platform_type_ref = { kind = "meshPlatformType", name = "STACKIT" }
        metering = {
          processing = {
            compact_timelines_after_days = 30
            delete_raw_data_after_days   = 65
          }
        }
      }
    }

    quota_definitions = []
  }
}

resource "meshstack_landingzone" "stackit_fake_default" {
  metadata = {
    name               = "stackit-fake-default"
    owned_by_workspace = var.workspace
    tags               = var.tags.landingzone
  }

  spec = {
    display_name                  = "STACKIT Project (Fake)"
    description                   = "A fake STACKIT project. The STACKIT Project building block sets its ID."
    automate_deletion_approval    = true
    automate_deletion_replication = true

    platform_ref = meshstack_platform.stackit_fake.ref

    platform_properties = {
      custom = {}
    }
  }
}

module "stackit_project" {
  source = "../modules/fake-definition"
  draft  = false

  display_name        = "STACKIT Project (Fake)"
  description         = "Fake of a STACKIT project for the dev environment. Creates nothing."
  symbol              = "${local.hub_symbol}/stackit/project/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  fake_git_ref        = var.fake_git_ref
  meshstack           = local.meshstack

  fake_service = {
    service       = "STACKIT Project"
    delay_seconds = 15
    fake_outputs = {
      project_id  = "{uuid}"
      project_url = "https://portal.stackit.cloud/dashboard?project={uuid}"
    }
  }
  outputs = {
    project_id  = { display_name = "STACKIT Project ID", type = "STRING", assignment_type = "PLATFORM_TENANT_ID" }
    project_url = { display_name = "Open in STACKIT Portal", type = "STRING", assignment_type = "RESOURCE_URL" }
  }
}

module "service_account" {
  source = "../modules/fake-definition"
  draft  = false

  display_name        = "STACKIT Service Account (Fake)"
  description         = "Fake of a STACKIT service account for the dev environment. Creates nothing."
  symbol              = "${local.hub_symbol}/stackit/service-account/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  fake_git_ref        = var.fake_git_ref
  meshstack           = local.meshstack

  fake_service = {
    service       = "STACKIT Service Account"
    delay_seconds = 6
    fake_outputs = {
      service_account_email = "sa-{suffix}@sa.stackit.fake.invalid"
      service_account_id    = "{uuid}"
    }
  }
  inputs = {
    service_account_name = { display_name = "Service Account Name", type = "STRING", assignment_type = "USER_INPUT" }
    roles                = { display_name = "Roles", type = "CODE", assignment_type = "USER_INPUT", default_value = jsonencode(jsonencode([])) }
  }
  outputs = {
    service_account_email = { display_name = "Service Account Email", type = "STRING", assignment_type = "NONE" }
    service_account_id    = { display_name = "Service Account ID", type = "STRING", assignment_type = "NONE" }
  }
}

module "service_account_federation" {
  source = "../modules/fake-definition"
  draft  = false

  display_name        = "STACKIT Service Account Federation (Fake)"
  description         = "Fake of the workload identity federation that lets building block runs act as a STACKIT service account. Creates nothing."
  symbol              = "${local.hub_symbol}/stackit/service-account-federation/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  fake_git_ref        = var.fake_git_ref
  meshstack           = local.meshstack

  fake_service = {
    service       = "STACKIT Service Account Federation"
    delay_seconds = 4
  }
  inputs = {
    service_account_email                = { display_name = "Service Account Email", type = "STRING", assignment_type = "USER_INPUT" }
    federated_building_block_definitions = { display_name = "Federated Building Block Definitions", type = "CODE", assignment_type = "USER_INPUT", updateable_by_consumer = true }
  }
}

module "reference_architecture" {
  source = "../reference-architecture"

  fake_git_ref = var.fake_git_ref
  meshstack    = { owning_workspace_identifier = var.workspace, tags = {}, runner_ref = var.runner_ref }
  hub          = { git_ref = var.hub_git_ref, bbd_draft = false }
}

locals {
  tag_entries = { for kind, tags in { landingzone = var.tags.landingzone, project = var.tags.project, starterkit_project = var.tags.starterkit_project } : kind => [for key, values in tags : { key = key, values = values }] }
}

resource "meshstack_building_block" "reference_architecture" {
  wait_for_completion = false

  spec = {
    building_block_definition_version_ref = module.reference_architecture.building_block_definition.version_ref
    display_name                          = "STACKIT Kubernetes Platform ${var.platform_identifier}"
    target_ref                            = { kind = "meshWorkspace", name = var.workspace }

    inputs = {
      platform_identifier = { value = jsonencode(var.platform_identifier) }
      phase2_completed    = { value = jsonencode(var.phase2_completed) }
      use_global_location = { value = jsonencode(true) }
      playground_mode     = { value = jsonencode(false) }
      payment_method      = { value = jsonencode({ kind = "meshPaymentMethod", name = var.payment_method }) }
      landingzone_variant = { value = jsonencode("default") }
      dns_domain          = { value = jsonencode("stackit.run") }
      overrides           = { value = jsonencode(jsonencode(var.project_identifier == null ? {} : { project_identifier = var.project_identifier })) }

      landingzone = { value = jsonencode(jsonencode({
        platform_ref                               = { uuid = meshstack_platform.stackit_fake.metadata.uuid }
        landingzone_refs                           = { default = { name = meshstack_landingzone.stackit_fake_default.metadata.name } }
        project_bbd_version_ref                    = module.stackit_project.building_block_definition.version_ref
        service_account_bbd_version_ref            = module.service_account.building_block_definition.version_ref
        service_account_federation_bbd_version_ref = module.service_account_federation.building_block_definition.version_ref
      })) }

      stages = { value = jsonencode(jsonencode([
        for name, stage in var.tags.stages : {
          name        = name
          landingzone = [for key, values in stage.landingzone : { key = key, values = values }]
          project     = [for key, values in stage.project : { key = key, values = values }]
        }
      ])) }

      tags = { value = jsonencode(jsonencode(merge({
        landingzone               = local.tag_entries.landingzone
        building_block            = []
        starterkit_building_block = []
        project                   = local.tag_entries.project
        starterkit_project        = local.tag_entries.starterkit_project
      }, var.project_owner_tag_key == null ? {} : { project_owner_tag_key = var.project_owner_tag_key }))) }

    }
  }
}
