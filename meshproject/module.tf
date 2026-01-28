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

variable "building_block_definition_version_uuid" {
  type        = string
  description = "The uuid of the building block definition version that will be used for the creation of another building block."
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
    owned_by_workspace  = meshstack_project.example.metadata.owned_by_workspace
    owned_by_project    = meshstack_project.example.metadata.name
    platform_identifier = "sr.global"
  }

  spec = {
    # landing_zone_identifier is optional for SERVICEREGISTRY platform type
  }
}

resource "meshstack_building_block_v2" "workspace_bb" {
  spec = {
    building_block_definition_version_ref = {
      uuid = var.building_block_definition_version_uuid
    }

    display_name = "My BB for ${var.project_identifier}"
    target_ref = {
      kind       = "meshWorkspace"
      identifier = var.workspace_identifier
    }

    inputs = {
      fsd = { value_string = "example-value" }
    }
  }
}
