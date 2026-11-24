module "secrets_manager_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT Secrets Manager (Fake)"
  description         = "Fake of the STACKIT Secrets Manager for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/stackit/secrets-manager/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT Secrets Manager"
    delay_seconds = 8
    fake_outputs  = { instance_id = "{uuid}" }
  }
  outputs = {
    instance_id = { display_name = "Instance ID", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "secrets_manager" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.secrets_manager_integration.building_block_definition.version_ref
    display_name                          = "Secrets Manager"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

module "cluster_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "SKE Cluster (Fake)"
  description         = "Fake of a STACKIT Kubernetes Engine cluster for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/ske/logo.svg"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT Kubernetes Engine"
    delay_seconds = 45
    fake_outputs = {
      cluster_name = var.cluster_name
      kube_host    = "https://api.${var.cluster_name}.{suffix}.ske.eu01.fake.invalid"
    }
  }
  outputs = {
    cluster_name = { display_name = "Cluster Name", type = "STRING", assignment_type = "NONE" }
    kube_host    = { display_name = "Kubernetes API Server", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "cluster" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.cluster_integration.building_block_definition.version_ref
    display_name                          = "SKE Cluster"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

locals {
  kube_host = jsondecode(meshstack_building_block.cluster.status.outputs["kube_host"].value)
}

module "kubernetes_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name              = "Kubernetes meshPlatform Credentials (Fake)"
  description               = "Fake of the in-cluster replicator and metering identities for the dev environment. Provisions nothing."
  symbol                    = "${local.hub_symbol}/kubernetes/platform/logo.png"
  supported_platforms       = local.stackit_platforms
  use_in_landing_zones_only = true
  dependency_refs           = [module.cluster_integration.building_block_definition.ref]
  approval_policies         = var.approval_policies
  meshstack                 = local.platform_meshstack

  fake_service = {
    service       = "Kubernetes meshPlatform Credentials"
    delay_seconds = 5
  }
}

resource "meshstack_building_block" "kubernetes_platform" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.cluster.ref]
    building_block_definition_version_ref = module.kubernetes_integration.building_block_definition.version_ref
    display_name                          = "Kubernetes meshPlatform Credentials"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

module "ingress_controller_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "Kubernetes Ingress Controller (Fake)"
  description         = "Fake of the HAProxy ingress controller and cert-manager for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/kubernetes/ingress-controller/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  dependency_refs     = [module.cluster_integration.building_block_definition.ref]
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "Kubernetes Ingress Controller"
    delay_seconds = 20
    fake_outputs  = { haproxy_lb_ip = "192.0.2.10" }
  }
  outputs = {
    haproxy_lb_ip = { display_name = "Load Balancer IP", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "ingress_controller" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.cluster.ref]
    building_block_definition_version_ref = module.ingress_controller_integration.building_block_definition.version_ref
    display_name                          = "Kubernetes Ingress Controller"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

locals {
  ingress_load_balancer_ip = jsondecode(meshstack_building_block.ingress_controller.status.outputs["haproxy_lb_ip"].value)
  dns_zone_name            = "${var.dns_subdomain}.${var.dns_parent_domain}"
}

module "dns_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT DNS Zone (Fake)"
  description         = "Fake of a STACKIT DNS zone for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/stackit/dns/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT DNS"
    delay_seconds = 10
    fake_outputs  = { dns_zone_name = local.dns_zone_name }
  }
  outputs = {
    dns_zone_name = { display_name = "DNS Zone", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "dns" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.ingress_controller.ref, meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.dns_integration.building_block_definition.version_ref
    display_name                          = "DNS Zone"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

module "ai_llm_integration" {
  count  = var.ai_model == null ? 0 : 1
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT AI Model Serving (Fake)"
  description         = "Fake of STACKIT AI Model Serving for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/stackit/ai-llm/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT AI Model Serving"
    delay_seconds = 15
    fake_outputs = {
      model_name = coalesce(var.ai_model, "none")
      api_url    = "https://api.openai-compat.model-serving.eu01.fake.invalid/v1"
    }
  }
  outputs = {
    model_name = { display_name = "Model", type = "STRING", assignment_type = "NONE" }
    api_url    = { display_name = "API URL", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "ai_llm" {
  count = var.ai_model == null ? 0 : 1

  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.ai_llm_integration[0].building_block_definition.version_ref
    display_name                          = "AI Model Serving"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

module "git_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT Git (Fake)"
  description         = "Fake of a STACKIT Git (Forgejo) instance for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/stackit/git/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT Git"
    delay_seconds = 30
    fake_outputs = {
      instance_id          = "{uuid}"
      instance_url         = "https://${var.platform_identifier}.git.fake.invalid"
      forgejo_organization = var.platform_identifier
    }
  }
  outputs = {
    instance_id          = { display_name = "Instance ID", type = "STRING", assignment_type = "NONE" }
    instance_url         = { display_name = "Open STACKIT Git", type = "STRING", assignment_type = "RESOURCE_URL" }
    forgejo_organization = { display_name = "Forgejo Organization", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "git" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.git_integration.building_block_definition.version_ref
    display_name                          = "STACKIT Git Instance"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

module "container_registry_integration" {
  source = "git::https://github.com/meshcloud/building-blocks-playground.git//ske-fake/modules/fake-definition?ref=ske-fake"

  display_name        = "STACKIT Container Registry (Fake)"
  description         = "Fake of a STACKIT Container Registry (Harbor) project for the dev environment. Provisions nothing."
  symbol              = "${local.hub_symbol}/stackit/container-registry/buildingblock/logo.png"
  supported_platforms = local.stackit_platforms
  approval_policies   = var.approval_policies
  meshstack           = local.platform_meshstack

  fake_service = {
    service       = "STACKIT Container Registry"
    delay_seconds = 15
    fake_outputs = {
      registry_host      = "registry.fake.invalid"
      registry_name      = lower(var.platform_identifier)
      registry_url       = "https://registry.fake.invalid/harbor/projects/${lower(var.platform_identifier)}"
      registry_robot_url = "https://registry.fake.invalid/harbor/projects/${lower(var.platform_identifier)}/robot-account"
    }
  }
  outputs = {
    registry_host      = { display_name = "Registry Host", type = "STRING", assignment_type = "NONE" }
    registry_name      = { display_name = "Registry Name", type = "STRING", assignment_type = "NONE" }
    registry_url       = { display_name = "Open Registry", type = "STRING", assignment_type = "RESOURCE_URL" }
    registry_robot_url = { display_name = "Robot Accounts", type = "STRING", assignment_type = "NONE" }
  }
}

resource "meshstack_building_block" "container_registry" {
  wait_for_completion = true

  lifecycle {
    postcondition {
      condition     = self.status.succeeded
      error_message = "Building block ${self.metadata.uuid} did not succeed (health status ${self.status.health_status}, action ${self.status.action}). See its run in meshPanel."
    }
  }

  spec = {
    parent_building_block_refs            = [meshstack_building_block.platform_federation.ref]
    building_block_definition_version_ref = module.container_registry_integration.building_block_definition.version_ref
    display_name                          = "STACKIT Container Registry"
    target_ref                            = local.tenant_ref
    inputs                                = {}
  }
}

locals {
  registry_host = jsondecode(meshstack_building_block.container_registry.status.outputs["registry_host"].value)
  registry_name = jsondecode(meshstack_building_block.container_registry.status.outputs["registry_name"].value)

  forgejo_instance_url = jsondecode(meshstack_building_block.git.status.outputs["instance_url"].value)
  forgejo_instance_id  = jsondecode(meshstack_building_block.git.status.outputs["instance_id"].value)
  forgejo_organization = jsondecode(meshstack_building_block.git.status.outputs["forgejo_organization"].value)
}
