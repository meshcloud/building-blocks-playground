output "reference_architecture_building_block_uuid" {
  value = meshstack_building_block.reference_architecture.metadata.uuid
}

output "stackit_platform_uuid" {
  value = meshstack_platform.stackit_fake.metadata.uuid
}
