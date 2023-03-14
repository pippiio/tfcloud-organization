resource "tfe_project" "this" {
  for_each = var.projects

  organization = tfe_organization.this.name
  name         = each.key
}
