# Parameters only: the logic lives in stacks/azure-iis-vm.
module "stack" {
  source = "../../../../stacks/azure-iis-vm"

  app                 = "legacy-portal"
  environment         = "prod"
  owner               = "team-portal"
  vnet_cidr           = "10.20.2.0/24"
  vm_size             = "Standard_D4s_v5"
  waf_subnet_cidr     = "10.0.1.0/26" # hub: Application Gateway WAF
  bastion_subnet_cidr = "10.0.2.0/26" # hub: AzureBastionSubnet
  ansible_runner_cidr = "10.0.3.0/26" # hub: self-hosted runners (Ansible)
}

output "vm_name" {
  value = module.stack.vm_name
}
