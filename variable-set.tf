resource "tfe_variable_set" "this" {
  for_each = var.variable_sets

  organization = tfe_organization.this.name
  name         = coalesce(each.value.name, each.key)
  description  = each.value.description
  global       = each.value.organization_scope
}

resource "tfe_variable" "this" {
  for_each = { for entry in flatten([
    for variable_set_name, variable_set in var.variable_sets : [
      for name, variable in variable_set.variables : {
        key          = "${variable_set_name}/${name}"
        variable_set = variable_set_name
        name         = name
        value        = variable.value
        sensitive    = variable.sensitive
        description  = variable.description
  }]]) : entry.key => entry }

  key             = each.value.name
  value           = each.value.value
  category        = "terraform"
  description     = each.value.description
  sensitive       = each.value.sensitive
  hcl             = can(jsondecode(each.value.value)) # Treat complex types as hcl
  variable_set_id = tfe_variable_set.this[each.value.variable_set].id
}
