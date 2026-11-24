locals {
  fake_service_inputs = var.fake_service == null ? {} : {
    service = {
      display_name    = "Faked Service"
      description     = "STACKIT service this building block pretends to provision."
      type            = "STRING"
      assignment_type = "STATIC"
      argument        = jsonencode(var.fake_service.service)
    }
    delay_seconds = {
      display_name    = "Provisioning Delay (Seconds)"
      description     = "How long the first run waits, to feel like provisioning on STACKIT."
      type            = "INTEGER"
      assignment_type = "STATIC"
      argument        = jsonencode(var.fake_service.delay_seconds)
    }
    fake_outputs = {
      display_name    = "Fake Outputs"
      description     = "Output values the fake returns. `{uuid}` and `{suffix}` are generated once per building block."
      type            = "CODE"
      assignment_type = "STATIC"
      argument        = jsonencode(jsonencode(var.fake_service.fake_outputs))
    }
  }
}

resource "meshstack_building_block_definition" "this" {
  metadata = {
    owned_by_workspace = var.meshstack.owning_workspace_identifier
    tags               = var.meshstack.tags
  }

  spec = {
    display_name              = var.display_name
    symbol                    = var.symbol
    description               = var.description
    readme                    = var.readme
    support_url               = "https://github.com/meshcloud/building-blocks-playground/tree/${var.fake_git_ref}/ske-fake"
    target_type               = var.target_type
    supported_platforms       = var.supported_platforms
    use_in_landing_zones_only = var.use_in_landing_zones_only
    run_transparency          = true
    approval_policies         = var.approval_policies
  }

  version_spec = {
    draft           = var.draft
    runner_ref      = var.meshstack.runner_ref
    deletion_mode   = "DELETE"
    dependency_refs = var.dependency_refs

    implementation = {
      terraform = {
        terraform_version              = "1.12.5"
        repository_url                 = "https://github.com/meshcloud/building-blocks-playground.git"
        repository_path                = var.implementation_path
        ref_name                       = var.fake_git_ref
        use_mesh_http_backend_fallback = true
      }
    }

    inputs = merge(local.fake_service_inputs, var.inputs)

    outputs = merge(var.outputs, {
      summary = {
        display_name    = "Summary"
        type            = "STRING"
        assignment_type = "SUMMARY"
      }
    })
  }
}
