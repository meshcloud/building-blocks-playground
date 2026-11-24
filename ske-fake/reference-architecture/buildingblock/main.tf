locals {
  overrides = coalesce(var.overrides, { cluster_name = null, cluster_issuer_email = null, project_identifier = null })

  starterkit_add_random_name_suffix = var.playground_mode ? true : var.starterkit_add_random_name_suffix
  dns_domain                        = var.playground_mode ? "stackit.run" : var.dns_domain
  approval_policies                 = var.playground_mode ? local.no_approval : var.approval_policies
  starterkit_approval_policies      = var.playground_mode ? local.no_approval : var.starterkit_approval_policies

  no_approval = {
    building_block_creation = false
    user_input_changes      = false
    any_input_changes       = false
    manual_triggers         = false
    version_upgrade         = false
  }

  platform_identifier = var.playground_mode ? "${var.platform_identifier}-${random_string.playground_suffix.result}" : var.platform_identifier

  platform_service_account_name = length(local.platform_identifier) <= 20 ? local.platform_identifier : format(
    "%s-%s",
    replace(substr(local.platform_identifier, 0, 15), "/-+$/", ""),
    substr(sha256(local.platform_identifier), 0, 4)
  )

  project_identifier = coalesce(local.overrides.project_identifier, "${local.platform_identifier}-ske")

  project_display_name = "STACKIT Kubernetes Platform ${local.platform_identifier}"

  release_imports_on_destroy = var.playground_mode && local.imports.project != null

  tag_maps = {
    for kind in ["landingzone", "building_block", "starterkit_building_block", "project", "starterkit_project"] :
    kind => { for tag in var.tags[kind] : tag.key => tag.values }
  }

  stages = {
    for stage in var.stages : stage.name => {
      landingzone = { for tag in stage.landingzone : tag.key => tag.values }
      project     = { for tag in stage.project : tag.key => tag.values }
      quotas      = stage.quotas
    }
  }

  owner_tags = var.tags.project_owner_tag_key == null ? {} : { (var.tags.project_owner_tag_key) = [var.creator.displayName] }

  platform_admins = toset([
    for member in var.workspace_members : member.username
    if contains(member.roles, "Workspace Owner") || contains(member.roles, "Workspace Manager")
  ])

  admin_binding_names = merge({
    for username in local.platform_admins : username => format(
      "%s-admin-%s",
      substr(local.platform_identifier, 0, 20),
      substr(sha256("${local.platform_identifier}:${username}"), 0, 12),
    )
  }, local.admin_binding_imports)

  tenant_project_id  = module.tenant.tenant.spec.platform_tenant_id
  stackit_project_id = local.tenant_project_id != null && local.tenant_project_id != "" ? local.tenant_project_id : try(jsondecode(module.stackit_project.building_block.status.outputs["project_id"].value), "")
}

resource "terraform_data" "playground_mode" {
  input = var.playground_mode

  lifecycle {
    ignore_changes = [input]

    postcondition {
      condition     = self.output == var.playground_mode
      error_message = "playground_mode cannot change after the order."
    }
  }
}

resource "terraform_data" "starterkit_add_random_name_suffix" {
  input = local.starterkit_add_random_name_suffix

  lifecycle {
    ignore_changes = [input]

    postcondition {
      condition     = self.output == local.starterkit_add_random_name_suffix
      error_message = "starterkit_add_random_name_suffix cannot change after the order."
    }
  }
}

resource "random_string" "playground_suffix" {
  lifecycle {
    enabled = var.playground_mode
  }

  length  = 6
  special = false
  upper   = false
}

module "project" {
  source = "./modules/project"

  release_on_destroy = local.release_imports_on_destroy

  metadata = {
    name               = local.project_identifier
    owned_by_workspace = var.workspace
  }

  spec = {
    display_name              = local.project_display_name
    payment_method_identifier = var.payment_method.name
    tags                      = merge(local.tag_maps.project, local.owner_tags)
  }
}

moved {
  from = meshstack_project.platform
  to   = module.project.meshstack_project.this
}

module "project_admin_bindings" {
  source = "./modules/project-admin-bindings"

  project = {
    owned_by_workspace = var.workspace
    name               = module.project.project.metadata.name
  }

  bindings = {
    for username, name in local.admin_binding_names : username => {
      name               = name
      release_on_destroy = local.release_imports_on_destroy && contains(keys(local.admin_binding_imports), username)
    }
  }
}

moved {
  from = meshstack_project_user_binding.admin
  to   = module.project_admin_bindings.meshstack_project_user_binding.this
}

module "tenant" {
  source = "./modules/tenant"

  release_on_destroy = local.release_imports_on_destroy

  prevent_destroy = !var.playground_mode

  wait_for_completion = false

  metadata = {
    owned_by_workspace = var.workspace
    owned_by_project   = module.project.project.metadata.name
  }

  spec = {
    platform_ref     = var.landingzone.platform_ref
    landing_zone_ref = var.landingzone.landingzone_refs[var.landingzone_variant]
  }
}

moved {
  from = meshstack_tenant.stackit_project
  to   = module.tenant.meshstack_tenant.this
}

module "stackit_project" {
  source = "./modules/stackit-project"

  release_on_destroy = local.release_imports_on_destroy
  prevent_destroy    = !var.playground_mode

  definition_version_ref = var.landingzone.project_bbd_version_ref
  display_name           = "STACKIT Project"
  target_ref             = module.tenant.tenant.ref

  depends_on = [module.project_admin_bindings]
}
