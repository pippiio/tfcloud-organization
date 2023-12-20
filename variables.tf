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
      description = string
      tfversion   = optional(string, "~> 1.6.0")
      vcs = optional(object({
        repository  = string
        branch      = optional(string, "main")
        working_dir = optional(string)
        trigger     = optional(string, "path")
        pattern     = optional(string)
      }))
      variable_sets = optional(set(string), [])
      tags          = optional(set(string), [])
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
      vcs             :
        repository    : A reference to your VCS repository in the format <organization>/<repository>
        path          : The path to the terraform code inside the repo.
      variable_sets   : A set of variable sets that should be applyed to the workspace
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
