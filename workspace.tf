resource "tfe_workspace" "this" {
  for_each = { for entry in flatten([
    for project_name, project in var.projects : [
      for name, workspace in project.workspaces : {
        project   = project_name
        name      = name
        workspace = workspace
  }]]) : entry.name => entry }

  name                  = each.value.name
  organization          = tfe_organization.this.id
  project_id            = tfe_project.this[each.value.project].id
  description           = each.value.workspace.description
  auto_apply            = each.value.workspace.vcs != null
  allow_destroy_plan    = false
  queue_all_runs        = false
  assessments_enabled   = false
  terraform_version     = each.value.workspace.tfversion
  working_directory     = each.value.workspace.vcs != null ? each.value.workspace.vcs.working_dir : null
  tag_names             = each.value.workspace.vcs != null ? toset(concat([replace(reverse(split("/", lower(each.value.workspace.vcs.repository)))[0], ".", "_")], tolist(each.value.workspace.tags))) : each.value.workspace.tags
  file_triggers_enabled = try(each.value.workspace.vcs.trigger == "path", null)
  trigger_patterns      = try(each.value.workspace.vcs.trigger == "path" ? compact([each.value.workspace.vcs.pattern]) : null, null)

  dynamic "vcs_repo" {
    for_each = each.value.workspace.vcs != null ? [1] : []

    content {
      branch         = each.value.workspace.vcs.branch
      identifier     = each.value.workspace.vcs.repository
      oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
      tags_regex     = each.value.workspace.vcs.trigger == "tag" ? coalesce(each.value.workspace.vcs.pattern, "^v[0-9]+\\.[0-9]+\\.[0-9]+$") : null
    }
  }
}

resource "tfe_workspace_settings" "this" {
  for_each = { for entry in flatten([
    for project_name, project in var.projects : [
      for name, workspace in project.workspaces : {
        project   = project_name
        name      = name
        workspace = workspace
  }]]) : entry.name => entry }

  workspace_id   = tfe_workspace.this[each.value.name].id
  execution_mode = each.value.workspace.execution_mode
}

resource "tfe_workspace_variable_set" "this" {
  for_each = { for entry in flatten([
    for project_name, project in var.projects : [
      for workspace_name, workspace in project.workspaces : [
        for variable_set in workspace.variable_sets : {
          key          = "${workspace_name}/${variable_set}"
          workspace    = workspace_name
          variable_set = variable_set
  }]]]) : entry.key => entry if !var.variable_sets[entry.variable_set].organization_scope }

  workspace_id    = tfe_workspace.this[each.value.workspace].id
  variable_set_id = tfe_variable_set.this[each.value.variable_set].id
}

resource "tfe_team_access" "this" {
  for_each = { for entry in flatten([
    for project_name, project in var.projects : [
      for name, workspace in project.workspaces : [
        for team, access in workspace.teams : {
          workspace = name
          team      = team
          access    = access
      }]
  ]]) : "${entry.workspace}/${entry.team}" => entry }

  access       = each.value.access != "contributer" ? each.value.access : null
  team_id      = tfe_team.this[each.value.team].id
  workspace_id = tfe_workspace.this[each.value.workspace].id

  dynamic "permissions" {
    for_each = each.value.access == "contributer" ? [1] : []

    content {
      runs              = "apply"
      variables         = "write"
      state_versions    = "read"
      sentinel_mocks    = "none"
      workspace_locking = false
      run_tasks         = false
    }
  }
}

resource "tfe_team" "ws_token" {
  for_each = toset(flatten([
    for project in values(var.projects) : [
      for name, workspace in project.workspaces :
      name if workspace.create_token
  ]]))

  name         = "ws_${each.key}"
  organization = tfe_organization.this.name
  visibility   = "secret"
}

resource "tfe_team_access" "ws_token" {
  for_each = { for _ in flatten([for project in values(var.projects) : [
    for name, workspace in project.workspaces : {
      workspace  = name
      allow_lock = workspace.execution_mode == "local"
    } if workspace.create_token
  ]]) : _.workspace => _.allow_lock }

  team_id      = tfe_team.ws_token[each.key].id
  workspace_id = tfe_workspace.this[each.key].id

  permissions {
    runs              = "apply"
    variables         = "read"
    state_versions    = "write"
    sentinel_mocks    = "none"
    workspace_locking = each.value
    run_tasks         = false
  }
}

resource "tfe_team_token" "ws_token" {
  for_each = tfe_team.ws_token

  team_id = tfe_team.ws_token[each.key].id
}
