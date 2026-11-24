resource "meshstack_project" "this" {
  lifecycle {
    enabled = !var.release_on_destroy
  }

  metadata = var.metadata
  spec     = var.spec
}

resource "meshstack_project" "released" {
  lifecycle {
    enabled         = var.release_on_destroy
    destroy         = false
    prevent_destroy = true
  }

  metadata = var.metadata
  spec     = var.spec
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
