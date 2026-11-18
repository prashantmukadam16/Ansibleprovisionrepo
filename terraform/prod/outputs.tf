output "vm_public_ips" {
  description = "Public IP addresses of the provisioned production VMs."
  value       = module.vm.instances
}

output "vpc_name" {
  value = module.network.network_name
}
