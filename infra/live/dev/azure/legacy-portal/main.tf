# Parameters only: the logic lives in stacks/azure-iis-vm.
module "stack" {
  source = "../../../../stacks/azure-iis-vm"

  app                 = "legacy-portal"
  environment         = "dev"
  owner               = "team-portal"
  vnet_cidr           = "10.10.2.0/24"
  vm_size             = "Standard_D2s_v5"
  waf_subnet_cidr     = "10.1.1.0/26" # hub: Application Gateway WAF
  bastion_subnet_cidr = "10.1.2.0/26" # hub: AzureBastionSubnet
  ansible_runner_cidr = "10.1.3.0/26" # hub: self-hosted runners (Ansible)
}

output "vm_name" {
  value = module.stack.vm_name
}
