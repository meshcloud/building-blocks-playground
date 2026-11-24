resource "random_uuid" "id" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "time_sleep" "provisioning" {
  create_duration = "${var.delay_seconds}s"

  triggers = {
    id = random_uuid.id.result
  }
}

locals {
  values = {
    for name, value in var.fake_outputs :
    name => replace(replace(value, "{uuid}", time_sleep.provisioning.triggers.id), "{suffix}", random_string.suffix.result)
  }
}
