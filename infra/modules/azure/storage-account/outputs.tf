output "id" { value = azurerm_storage_account.this.id }
output "name" { value = azurerm_storage_account.this.name }
output "container_ids" { value = { for k, c in azurerm_storage_container.this : k => c.id } }
