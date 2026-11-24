locals {
  meshstack  = { owning_workspace_identifier = var.workspace, tags = {}, runner_ref = var.runner_ref }
  hub_symbol = "https://raw.githubusercontent.com/meshcloud/meshstack-hub/${var.hub_git_ref}/modules"

  instance_hosts = {
    for stage in var.stages :
    "${var.platform_identifier}-namespace-${stage}" => jsondecode(meshstack_building_block.instance[stage].status.outputs["host"].value)
  }
}

module "instance" {
  source = "../../modules/fake-definition"

  display_name        = "STACKIT PostgreSQL Flex Instance (Fake)"
  description         = "Fake of a shared STACKIT PostgreSQL Flex instance for one stage. Creates nothing."
  symbol              = "${local.hub_symbol}/stackit/postgres/buildingblock/logo.png"
  supported_platforms = [{ name = "STACKIT" }]
  fake_git_ref        = var.fake_git_ref
  meshstack           = local.meshstack

  fake_service = {
    service       = "STACKIT PostgreSQL Flex"
    delay_seconds = 30
    fake_outputs = {
      instance_id = "{uuid}"
      host        = "pg-{suffix}.postgresql.eu01.onstackit.fake.invalid"
    }
  }
  inputs = {
    stage = { display_name = "Stage", type = "STRING", assignment_type = "USER_INPUT" }
  }
  outputs = {
    instance_id = { display_name = "Instance ID", type = "STRING", assignment_type = "NONE" }
    host        = { display_name = "Host", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "instance" {
  for_each = toset(var.stages)

  wait_for_completion = true

  spec = {
    building_block_definition_version_ref = module.instance.building_block_definition.version_ref
    display_name                          = "PostgreSQL ${each.key}"
    target_ref                            = { kind = "meshTenant", uuid = var.stackit_tenant_uuid }

    inputs = {
      stage = { value = jsonencode(each.key) }
    }
  }
}

module "postgres_db" {
  source = "../../modules/fake-definition"

  display_name        = "Postgres DB (Fake)"
  description         = "A PostgreSQL database of your own on the stage's shared instance, with its credentials as a Kubernetes Secret in your namespace. Fake: creates nothing."
  symbol              = "${local.hub_symbol}/stackit/postgres/buildingblock/logo.png"
  supported_platforms = [{ name = "SKE-FAKE" }]
  implementation_path = "ske-fake/modules/postgres-db"
  fake_git_ref        = var.fake_git_ref
  meshstack           = local.meshstack

  inputs = {
    workspace_identifier    = { display_name = "Workspace", type = "STRING", assignment_type = "WORKSPACE_IDENTIFIER" }
    project_identifier      = { display_name = "Project", type = "STRING", assignment_type = "PROJECT_IDENTIFIER" }
    namespace               = { display_name = "Namespace", type = "STRING", assignment_type = "PLATFORM_TENANT_ID" }
    landing_zone_identifier = { display_name = "Landing Zone", type = "STRING", assignment_type = "LANDING_ZONE_IDENTIFIER", description = "Landing zone of the tenant. It selects the shared instance." }
    enable_audit = {
      display_name    = "Audit logging"
      description     = "Records every change to your tables in an audit trail. Production only."
      type            = "BOOLEAN"
      assignment_type = "USER_INPUT"
      default_value   = jsonencode(false)
      condition       = "input.landing_zone_identifier == \"${var.platform_identifier}-namespace-prod\""
    }
    instance_hosts = { display_name = "Instance Hosts", type = "CODE", assignment_type = "STATIC", argument = jsonencode(jsonencode(local.instance_hosts)) }
    delay_seconds  = { display_name = "Delay", type = "INTEGER", assignment_type = "STATIC", argument = jsonencode(12) }
  }
  outputs = {
    database    = { display_name = "Database", type = "STRING", assignment_type = "NONE" }
    username    = { display_name = "Username", type = "STRING", assignment_type = "NONE" }
    host        = { display_name = "Host", type = "STRING", assignment_type = "NONE" }
    port        = { display_name = "Port", type = "INTEGER", assignment_type = "NONE" }
    secret_name = { display_name = "Kubernetes Secret", type = "STRING", assignment_type = "NONE" }
  }
}

output "postgres_db_definition_uuid" {
  value = module.postgres_db.building_block_definition.uuid
}
