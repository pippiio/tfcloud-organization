resource "tfe_organization" "this" {
  name                     = var.organization.organization
  email                    = var.organization.email
  collaborator_auth_policy = "two_factor_mandatory"
}

resource "tfe_team" "this" {
  for_each = local.teams

  name         = each.key
  organization = tfe_organization.this.name
}

resource "tfe_team_access" "this" {
  for_each = { for index, value in flatten([for name, workspaces in local.teams : [
    for _, w in workspaces : {
      team      = name
      workspace = w
    }
  ]]) : "${value.team}:${value.workspace}" => value }

  access       = "admin"
  team_id      = tfe_team.this[each.value.team].id
  workspace_id = tfe_workspace.this[each.value.workspace].id
}

resource "tfe_team_token" "this" {
  for_each = tfe_team.this

  team_id = each.value.id
}
