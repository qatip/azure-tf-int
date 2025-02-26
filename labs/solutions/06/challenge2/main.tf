locals {
  # Load JSON file containing inconsistent VM names
  resource_data = jsondecode(file("./resource-names.json"))

  # Define regex patterns for stages and projects
  stage_pattern   = join("|", var.stages)
  project_pattern = join("|", var.projects)

  # Process and clean each VM name dynamically
  corrected_vm_names = {
    for name in local.resource_data.inconsistent_names :
    name => "${try(regex(local.stage_pattern, name), "invalid_stage")}-${try(regex(local.project_pattern, name), "invalid_project")}-${try(regex("([a-z0-9]+)$", name)[0])}"
  }
}

# Output the corrected VM names
output "corrected_vm_names" {
  value = local.corrected_vm_names
}
