data "tfe_oauth_client" "github" {
  organization     = var.organization.organization
  service_provider = "github"
}

locals {
  teams = try(transpose(merge([for _, p in var.projects : { for wn, w in p.workspaces : wn => w.tags }]...)), [])
}
