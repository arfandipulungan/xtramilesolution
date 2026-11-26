output "client_ids" {
  description = "Set as GitHub environment variables (AZURE_CLIENT_ID) per environment"
  value       = { for k, i in azurerm_user_assigned_identity.this : k => i.client_id }
}
