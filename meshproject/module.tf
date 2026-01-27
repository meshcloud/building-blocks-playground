terraform {
  required_providers {
    meshstack = {
      source  = "meshcloud/meshstack"
      version = ">= 0.17.0"
    }
  }
}

provider "meshstack" {
}

variable "project_identifier" {
  type        = string
  description = "The identifier of the meshStack project to be created."
}

variable "workspace_identifier" {
  type        = string
  description = "The identifier of the meshStack workspace."
}

resource "meshstack_project" "example" {
  metadata = {
    name               = var.project_identifier
    owned_by_workspace = var.workspace_identifier
  }
  spec = {
    payment_method_identifier = "managed-customer"
    display_name              = "My Project ${var.project_identifier}"
    tags = {
    }
  }
}

resource "meshstack_tenant" "sr_global" {
  metadata = {
    owned_by_workspace  = var.workspace_identifier
    owned_by_project    = var.project_identifier
    platform_identifier = "sr.global"
  }

  spec = {
    # landing_zone_identifier is optional for SERVICEREGISTRY platform type
  }
}

resource "meshstack_building_block_v2" "workspace_bb" {
  spec = {
    building_block_definition_version_ref = {
      uuid = "dcfbb560-fc0f-46d6-a07c-dbd89292e1b4"
    }

    display_name = "workspace-building-block"
    target_ref = {
      kind       = "meshWorkspace"
      identifier = var.workspace_identifier
    }

    inputs = {
      fsd = { value_string = "example-value" }
    }
  }
}
