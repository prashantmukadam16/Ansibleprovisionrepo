output "instances" {
  description = "Instance names and public IP addresses."
  value = [
    for vm in google_compute_instance.vm_instance : {
      name      = vm.name
      public_ip = vm.network_interface[0].access_config[0].nat_ip
      zone      = vm.zone
    }
  ]
}
