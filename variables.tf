variable "organization" {
  type = object({
    organization = string
    email        = string
  })
  description = <<-EOL
    Terraform Cloud organization configuration:

    organization : Name of the organization.
    email        : Admin email address
  EOL
}

variable "projects" {
  type = map(object({
    workspaces = map(object({
      description  = string
      tfversion    = optional(string, "~>1.8.0")
      create_token = optional(bool, false)
      vcs = optional(object({
        repository  = string
        branch      = optional(string, "main")
        working_dir = optional(string)
        trigger     = optional(string, "path")
        pattern     = optional(string)
      }))
      variable_sets  = optional(set(string), [])
      teams          = optional(map(string), {})
      tags           = optional(set(string), [])
      execution_mode = optional(string, "remote")
    }))
  }))

  validation {
    condition     = try(alltrue(flatten([for project in values(var.projects) : [for workspace_name in keys(project.workspaces) : length(regexall("^[A-Za-z0-9_-]+$", workspace_name)) > 0]])), true)
    error_message = "Invalid workspace name must only contain letters, numbers, dashes, and underscores"
  }

  description = <<-EOL
    A map of organization workspaces:

    Key   : Name of the workspace
    Value : 
      description     : A description for the workspace
      tfversion       : The Terraform version of the workspace
      create_token    : Wether to create a token dedicated for the workspace
      vcs             :
        repository    : A reference to your VCS repository in the format <organization>/<repository>
        path          : The path to the terraform code inside the repo.
      variable_sets   : A set of variable sets that should be applyed to the workspace
      teams           : A map of teams granted access to the workspace
        Key           : The name of the team         
        Value         : The access granted. Valid values [read, plan, write, admin] 
      tags            : A set of tags that is associated with am exported API token 
  EOL
}

variable "variable_sets" {
  type = map(object({
    name               = optional(string)
    description        = string
    organization_scope = optional(bool, false)
    variables = map(object({
      value       = string
      description = string
      sensitive   = optional(bool, false)
    }))
  }))
  default     = {}
  description = <<-EOL
    A map of organization variable sets:

    Key   : Name of the variable set
    Value : 
      description        : A description for the variable set
      organization_scope : Wether to shared with all workspaces in organization
      variables          : A map op variables in the set
        Key   : The variable key
        Value :
          value       : The variable value
          description : A description of the variable
          sensitive   : Wether the variable should be marked as sensitive
  EOL
}

variable "teams" {
  type = map(object({
    visible         = optional(bool, false)
    read_workspaces = optional(bool, false)
    read_projects   = optional(bool, false)
    create_token    = optional(bool, false)
    members         = set(string)
  }))
  default     = {}
  description = <<-EOL
    A map of organization teams:

    Key   : Name of the team
    Value : 
      visible         : Wether the team is visible for the entire organization
      read_workspaces : Wether the team can read all workspaces
      read_projects   : Wether the team can read all projects
      create_token    : Wether to create and output team token
      members         : A set of email addresses identifying team members
  EOL
}
