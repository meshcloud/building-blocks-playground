module "namespace_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name              = "SKE Kubernetes Namespace (Fake)"
  description               = "Fake of the namespace meshStack replicates onto the SKE cluster for every tenant. Creates nothing."
  symbol                    = "${local.hub_symbol}/ske/logo.svg"
  supported_platforms       = local.fake_platforms
  use_in_landing_zones_only = true
  implementation_path       = "ske-fake/modules/namespace"
  draft                     = var.hub.bbd_draft
  approval_policies         = var.approval_policies
  meshstack                 = local.platform_meshstack

  inputs = {
    workspace_identifier = {
      display_name    = "Workspace Identifier"
      type            = "STRING"
      assignment_type = "WORKSPACE_IDENTIFIER"
    }
    project_identifier = {
      display_name    = "Project Identifier"
      type            = "STRING"
      assignment_type = "PROJECT_IDENTIFIER"
    }
    landing_zone_identifier = {
      display_name    = "Landing Zone Identifier"
      type            = "STRING"
      assignment_type = "LANDING_ZONE_IDENTIFIER"
    }
    delay_seconds = {
      display_name    = "Replication Delay (Seconds)"
      type            = "INTEGER"
      assignment_type = "STATIC"
      argument        = jsonencode(5)
    }
  }
  outputs = {
    namespace = { display_name = "K8S Namespace", type = "STRING", assignment_type = "PLATFORM_TENANT_ID" }
  }
}

resource "meshstack_platform" "this" {
  metadata = {
    name               = var.platform_identifier
    owned_by_workspace = var.workspace
  }

  lifecycle {
    ignore_changes = [spec.availability]
  }

  spec = {
    display_name      = "Kubernetes namespace (${var.platform_identifier})"
    description       = "Provides a Kubernetes namespace with role-based access control and quotas. Fake: no cluster behind it."
    endpoint          = local.kube_host
    documentation_url = "https://docs.meshcloud.io/docs/meshstack.kubernetes.index.html"
    support_url       = ""

    location_ref = {
      name = local.location_name
    }

    availability = {
      publication_state        = "PUBLISHED"
      restriction              = "PUBLIC"
      restricted_to_workspaces = []
    }

    contributing_workspaces = []

    config = {
      custom = {
        platform_type_ref = { kind = "meshPlatformType", name = local.platform_type_name }
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

  depends_on = [meshstack_building_block.kubernetes_platform]
}

resource "meshstack_landingzone" "this" {
  for_each = local.landing_zones

  metadata = {
    name               = each.value.name
    owned_by_workspace = var.workspace
    tags               = merge(var.tags.landingzone, each.value.tags)
  }

  spec = {
    display_name                  = each.value.display_name
    description                   = each.value.description
    automate_deletion_approval    = true
    automate_deletion_replication = true

    platform_ref = meshstack_platform.this.ref

    platform_properties = {
      custom = {}
    }

    mandatory_building_block_refs = [
      { kind = "meshBuildingBlockDefinition", uuid = module.namespace_integration.building_block_definition.uuid },
    ]
  }
}
