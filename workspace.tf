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
  execution_mode        = "remote"
  auto_apply            = each.value.workspace.vcs != null
  allow_destroy_plan    = false
  queue_all_runs        = false
  assessments_enabled   = false
  terraform_version     = each.value.workspace.tfversion
  working_directory     = each.value.workspace.vcs != null ? each.value.workspace.vcs.working_dir : null
  tag_names             = each.value.workspace.vcs != null ? [replace(reverse(split("/", each.value.workspace.vcs.repository))[0], ".", "_")] : []
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
