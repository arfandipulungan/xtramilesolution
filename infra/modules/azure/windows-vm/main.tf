# Legacy .NET Framework 4.8 / IIS host (IaaS). No public IP, Trusted Launch,
# encryption at host, platform-managed patching, Azure Monitor Agent.
# IIS itself is configured by Ansible (role iis_baseline), not by Terraform.
resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!@#%^*-_=+"
}

# Break-glass local admin password lives only in Key Vault; day-to-day access is
# Entra ID login (AADLoginForWindows) through Azure Bastion, never public RDP.
resource "azurerm_key_vault_secret" "admin" {
  name            = "${var.name}-local-admin"
  value           = random_password.admin.result
  key_vault_id    = var.key_vault_id
  content_type    = "password"
  expiration_date = timeadd(plantimestamp(), "2160h")

  lifecycle {
    ignore_changes  = [expiration_date]
    prevent_destroy = true
  }
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "this" {
  #checkov:skip=CKV_AZURE_50:Only vetted extensions: Azure Monitor Agent (telemetry) and Entra ID login (no local accounts)
  name                       = var.name
  computer_name              = substr(replace(var.name, "-", ""), 0, 15)
  location                   = var.location
  resource_group_name        = var.resource_group_name
  size                       = var.size
  zone                       = var.zone
  admin_username             = "localadmin"
  admin_password             = random_password.admin.result
  network_interface_ids      = [azurerm_network_interface.this.id]
  encryption_at_host_enabled = true
  secure_boot_enabled        = true
  vtpm_enabled               = true
  patch_mode                 = "AutomaticByPlatform"
  patch_assessment_mode      = "AutomaticByPlatform"
  provision_vm_agent         = true
  allow_extension_operations = true
  # ansible_group drives the dynamic inventory (azure.azcollection.azure_rm)
  tags = merge(var.tags, { ansible_group = var.ansible_group })

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.image_sku
    version   = "latest"
  }

  boot_diagnostics {}
}

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  tags                       = var.tags
}

resource "azurerm_virtual_machine_extension" "entra_login" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

# The VM pulls release packages (Task 1 deploy-iis-vm) with its managed identity.
resource "azurerm_role_assignment" "release_reader" {
  scope                = var.release_container_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_virtual_machine.this.identity[0].principal_id
}
