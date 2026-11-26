output "resource_group" { value = azurerm_resource_group.this.name }
output "vm_name" { value = module.vm.name }
output "release_storage_account" { value = module.release_storage.name }
