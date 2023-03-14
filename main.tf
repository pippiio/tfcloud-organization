data "tfe_oauth_client" "github" {
  organization     = var.organization.organization
  service_provider = "github"
}

locals {
  teams = try(transpose(merge([
    for _, project in var.projects : {
      for workspace_name, workspace in project.workspaces : workspace_name => workspace.tags
  }]...)), [])
}
