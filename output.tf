output "workspaces" {
  value = [for name, workspace in tfe_workspace.this : {
    name           = name
    description    = workspace.description
    execution_mode = workspace.execution_mode
    git_repo       = try("${workspace.vcs_repo.branch}@${workspace.vcs_repo.identifier}", null)
  }]
  description = "A set of workspaces in Terraform Cloud"
}

output "team_token" {
  value     = { for team, token in tfe_team_token.this : team => token.token }
  sensitive = true
}

output "workspace_token" {
  value     = { for name, token in tfe_team_token.ws_token : name => token.token }
  sensitive = true
}
