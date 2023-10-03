output "workspaces" {
  value = [for name, workspace in tfe_workspace.this : {
    name           = name
    description    = workspace.description
    execution_mode = workspace.execution_mode
    git_repo       = try("${workspace.vcs_repo.branch}@${workspace.vcs_repo.identifier}", null)
  }]
  description = "A set of workspaces in Terraform Cloud"
}
