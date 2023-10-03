resource "tfe_organization" "this" {
  name                     = var.organization.organization
  email                    = var.organization.email
  collaborator_auth_policy = "two_factor_mandatory"
}
