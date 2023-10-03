data "tfe_oauth_client" "github" {
  organization     = var.organization.organization
  service_provider = "github"
}
