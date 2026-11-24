locals {
  phase2 = var.phase2_completed ? 1 : 0

  git_repository_definition = var.phase2_completed ? module.git_repository_integration[0].building_block_definition : null
}

module "git_repository_integration" {
  count  = local.phase2
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT Git Repository (Fake)"
  description         = "Fake of a Git repository on STACKIT Git (Forgejo) with team-based workspace member access. Creates nothing."
  symbol              = "${local.hub_symbol}/stackit/git-repository/buildingblock/logo.png"
  target_type         = "WORKSPACE_LEVEL"
  implementation_path = "ske-fake/modules/git-repository"
  approval_policies   = var.starterkit_approval_policies
  meshstack           = local.starterkit_meshstack
  draft               = var.hub.bbd_draft

  inputs = {
    STACKIT_SERVICE_ACCOUNT_EMAIL = {
      display_name    = "STACKIT Service Account Email"
      type            = "STRING"
      assignment_type = "STATIC"
      is_environment  = true
      argument        = jsonencode(local.service_account_email)
    }
    stackit_project_id = {
      display_name    = "STACKIT Project ID"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(var.stackit_project_id)
    }
    stackit_git_instance_id = {
      display_name    = "STACKIT Git Instance ID"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(local.forgejo_instance_id)
    }
    FORGEJO_HOST = {
      display_name    = "FORGEJO_HOST"
      type            = "STRING"
      assignment_type = "STATIC"
      is_environment  = true
      argument        = jsonencode(local.forgejo_instance_url)
    }
    forgejo_base_url = {
      display_name    = "Forgejo Base URL"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(local.forgejo_instance_url)
    }
    forgejo_organization = {
      display_name    = "STACKIT Git Forgejo Organization"
      description     = "Organization under which repositories will be created in Forgejo"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(local.forgejo_organization)
    }
    workspace_identifier = {
      display_name    = "Workspace Identifier"
      type            = "STRING"
      assignment_type = "WORKSPACE_IDENTIFIER"
    }
    workspace_members = {
      display_name    = "Workspace Members"
      description     = "Workspace members used to manage Forgejo team membership."
      type            = "CODE"
      assignment_type = "USER_PERMISSIONS"
    }
    name = {
      display_name                   = "Repository Name / Identifier"
      description                    = "Name of the Git repository (alphanumeric, dashes, dots, underscores)"
      type                           = "STRING"
      assignment_type                = "USER_INPUT"
      value_validation_regex         = "^[a-zA-Z0-9._-]+$"
      validation_regex_error_message = "Only alphanumeric characters, dots, dashes, and underscores are allowed."
    }
    description = {
      display_name           = "Repository Description"
      description            = "Short description of the repository."
      type                   = "STRING"
      assignment_type        = "USER_INPUT"
      updateable_by_consumer = true
      default_value          = jsonencode("")
    }
    private = {
      display_name           = "Private Repository"
      description            = "If true, the repository has private visibility in Forgejo."
      type                   = "BOOLEAN"
      assignment_type        = "USER_INPUT"
      updateable_by_consumer = true
      default_value          = jsonencode(true)
    }
    clone_addr = {
      display_name    = "Clone from URL"
      description     = "Optional URL to clone into this repository, e.g. 'https://github.com/owner/repo.git'. Leave `null` to create an empty repository."
      type            = "STRING"
      assignment_type = "USER_INPUT"
      default_value   = jsonencode("null")
    }
    default_branch = {
      display_name    = "Default Branch"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode("main")
    }
    action_variables = {
      display_name    = "Repository Action Variables"
      type            = "CODE"
      assignment_type = "STATIC"
      argument = jsonencode(jsonencode({
        HARBOR_REGISTRY = local.registry_host
        HARBOR_PROJECT  = local.registry_name
      }))
    }
    extra_action_variables = {
      display_name           = "Extra Action Variables"
      description            = "HCL map of Forgejo Actions variables for this repository only, merged over the platform-wide ones."
      type                   = "CODE"
      assignment_type        = "USER_INPUT"
      updateable_by_consumer = true
      default_value          = jsonencode(jsonencode({}))
    }
    delay_seconds = {
      display_name    = "Provisioning Delay (Seconds)"
      type            = "INTEGER"
      assignment_type = "STATIC"
      argument        = jsonencode(6)
    }
  }

  outputs = {
    repository_id        = { display_name = "Repository ID", type = "INTEGER", assignment_type = "NONE" }
    repository_owner     = { display_name = "Repository Owner", type = "STRING", assignment_type = "NONE" }
    repository_name      = { display_name = "Repository Name", type = "STRING", assignment_type = "NONE" }
    repository_html_url  = { display_name = "Open Repository", type = "STRING", assignment_type = "RESOURCE_URL" }
    repository_clone_url = { display_name = "HTTPS Clone URL", type = "STRING", assignment_type = "NONE" }
    repository_ssh_url   = { display_name = "SSH Clone URL", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "starterkit_federation" {
  count = local.phase2

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
    display_name                          = "Starter Kit Identity Federation"
    target_ref                            = local.tenant_ref

    inputs = {
      service_account_email = { value = jsonencode(local.service_account_email) }
      federated_building_block_definitions = {
        value = jsonencode(jsonencode([local.git_repository_definition.uuid]))
      }
    }
  }
}

module "forgejo_connector_integration" {
  count  = local.phase2
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "SKE Forgejo Connector (Fake)"
  description         = "Fake of the connector that wires a Forgejo repository to a Kubernetes namespace on STACKIT SKE. Runs a pretend pipeline of about 20 seconds."
  symbol              = "${local.hub_symbol}/ske/forgejo-connector/buildingblock/logo.png"
  supported_platforms = local.fake_platforms
  dependency_refs     = [local.git_repository_definition.ref]
  implementation_path = "ske-fake/modules/forgejo-connector"
  approval_policies   = var.starterkit_approval_policies
  meshstack           = local.starterkit_meshstack
  draft               = var.hub.bbd_draft

  inputs = {
    namespace = {
      display_name    = "K8S Namespace"
      type            = "STRING"
      assignment_type = "PLATFORM_TENANT_ID"
    }
    kube_host = {
      display_name    = "Kubernetes API Server"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(local.kube_host)
    }
    repository_owner = {
      display_name    = "repository_owner"
      type            = "STRING"
      assignment_type = "BUILDING_BLOCK_OUTPUT"
      argument        = jsonencode("${local.git_repository_definition.uuid}.repository_owner")
    }
    repository_name = {
      display_name    = "repository_name"
      type            = "STRING"
      assignment_type = "BUILDING_BLOCK_OUTPUT"
      argument        = jsonencode("${local.git_repository_definition.uuid}.repository_name")
    }
    stage = {
      display_name    = "stage"
      type            = "STRING"
      assignment_type = "USER_INPUT"
      default_value   = jsonencode("dev")
    }
    app_hostname = {
      display_name    = "app_hostname"
      type            = "STRING"
      assignment_type = "USER_INPUT"
    }
    additional_kubernetes_secrets = {
      display_name    = "additional_kubernetes_secrets"
      type            = "CODE"
      assignment_type = "STATIC"
      argument        = jsonencode(jsonencode(var.ai_model == null ? {} : { "stackit-ai" = "${var.platform_identifier}/stackit/ai-llm" }))
    }
    forgejo_host = {
      display_name    = "Forgejo Host"
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(local.forgejo_instance_url)
    }
    pipeline_seconds = {
      display_name    = "Pipeline Duration (Seconds)"
      type            = "INTEGER"
      assignment_type = "STATIC"
      argument        = jsonencode(20)
    }
  }

  outputs = {
    app_link    = { display_name = "Application", type = "STRING", assignment_type = "RESOURCE_URL" }
    actions_url = { display_name = "Pipeline", type = "STRING", assignment_type = "RESOURCE_URL" }
  }
}

module "ske_starterkit_integration" {
  count = local.phase2

  depends_on = [meshstack_building_block.starterkit_federation]

  source = "github.com/meshcloud/meshstack-hub//modules/ske/ske-starterkit?ref=97246e3c3d1fc0ac835a4574dd13667248eb6060"

  platform_ref      = meshstack_platform.this.ref
  landing_zone_refs = { for stage, lz in meshstack_landingzone.this : stage => lz.ref }

  building_block_definition_version_refs = {
    "git-repository"    = local.git_repository_definition.version_ref
    "forgejo-connector" = module.forgejo_connector_integration[0].building_block_definition.version_ref
  }

  app_name        = var.starterkit_app_name
  repo_clone_addr = var.starterkit_repo_clone_addr
  dns_zone_name   = local.dns_zone_name

  add_random_name_suffix = var.starterkit_add_random_name_suffix

  bbd_display_name = "SKE Starter Kit (Fake)"

  project_tags = {
    stages        = local.stage_project_tags
    owner_tag_key = var.tags.project_owner_tag_key
  }

  approval_policies = var.starterkit_approval_policies

  meshstack = local.starterkit_meshstack
  hub       = var.hub
}
