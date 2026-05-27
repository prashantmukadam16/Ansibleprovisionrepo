module "network" {

  source       = "../modules/network"
  network_name = "prod-vpc"
}

module "firewall" {

  source         = "../modules/firewall"
  firewall_name  = "allow-ssh-http-prod"
  network        = "prod-vpc"
}

module "vm" {

  source           = "../modules/vm"

  instance_count   = 2
  instance_name    = "prod-server"
  machine_type     = "e2-medium"
  zone             = var.zone
  network          = "prod-vpc"
  public_key_path  = "~/.ssh/id_rsa.pub"
}
