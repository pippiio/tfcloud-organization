resource "tfe_organization_membership" "this" {
  for_each = toset(flatten(values(merge(var.teams[*]...))[*].members))

  organization = tfe_organization.this.name
  email        = each.value
}

resource "tfe_team" "this" {
  for_each = var.teams

  name         = each.key
  organization = tfe_organization.this.name
  visibility   = each.value.visible ? "organization" : "secret"

  organization_access {
    read_workspaces = each.value.read_workspaces
    read_projects   = each.value.read_projects
  }
}

resource "tfe_team_organization_members" "this" {
  for_each = var.teams

  team_id                     = tfe_team.this[each.key].id
  organization_membership_ids = [for member in each.value.members : tfe_organization_membership.this[member].id]
}

resource "tfe_team_token" "this" {
  for_each = var.teams

  team_id = tfe_team.this[each.key].id
}
