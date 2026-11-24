resource "meshstack_building_block" "this" {
  lifecycle {
    enabled         = !var.release_on_destroy
    prevent_destroy = var.prevent_destroy

    ignore_changes = [spec.building_block_definition_version_ref]

    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  wait_for_completion = true

  spec = {
    building_block_definition_version_ref = var.definition_version_ref
    display_name                          = var.display_name
    target_ref                            = var.target_ref
    inputs                                = {}
  }
}

resource "meshstack_building_block" "released" {
  lifecycle {
    enabled         = var.release_on_destroy
    destroy         = false
    prevent_destroy = true
    ignore_changes  = [spec.building_block_definition_version_ref]

    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  wait_for_completion = true

  spec = {
    building_block_definition_version_ref = var.definition_version_ref
    display_name                          = var.display_name
    target_ref                            = var.target_ref
    inputs                                = {}
  }
}

resource "terraform_data" "release_on_destroy" {
  input = var.release_on_destroy

  lifecycle {
    ignore_changes = [input]

    postcondition {
      condition     = self.output == var.release_on_destroy
      error_message = "release_on_destroy cannot change once managed."
    }
  }
}
