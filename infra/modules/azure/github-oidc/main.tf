# Workload identities for GitHub Actions (no client secrets). One identity per purpose,
# each trusted only from one GitHub environment, each with least-privilege roles.
locals {
  issuer = "https://token.actions.githubusercontent.com"
  identities = {
    deploy = {
      github_environment = var.environment # Task 1 app deployments
      grants             = [for s in var.deploy_scopes : { scope = s, role = "Website Contributor" }]
    }
    tfplan = {
      github_environment = "infra-${var.environment}-plan" # Task 2 plan (read-only)
      grants = [
        { scope = var.subscription_id_scope, role = "Reader" },
        { scope = var.state_container_id, role = "Storage Blob Data Contributor" }, # state lock lease
      ]
    }
    tfapply = {
      github_environment = "infra-${var.environment}" # Task 2 apply (approval in prod)
      grants = [
        { scope = var.subscription_id_scope, role = "Contributor" },
        { scope = var.subscription_id_scope, role = "Role Based Access Control Administrator" },
        { scope = var.state_container_id, role = "Storage Blob Data Contributor" },
      ]
    }
  }
  grants = merge([
    for id, cfg in local.identities : {
      for g in cfg.grants : "${id}|${g.role}|${g.scope}" => merge(g, { identity = id })
    }
  ]...)
}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = local.identities
  name                = "id-github-${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each                  = local.identities
  name                      = "github-${replace(var.repository, "/", "-")}-${each.value.github_environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.this[each.key].id
  issuer                    = local.issuer
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:${var.repository}:environment:${each.value.github_environment}"
}

resource "azurerm_role_assignment" "this" {
  for_each             = local.grants
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.this[each.value.identity].principal_id
}
