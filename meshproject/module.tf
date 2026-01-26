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
    payment_method_identifier = "default"
    display_name              = "My Project ${var.project_identifier}"
    tags = {
    }
  }
}
