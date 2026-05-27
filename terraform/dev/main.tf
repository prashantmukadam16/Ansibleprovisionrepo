module "network" {

  source       = "../modules/network"
  network_name = "dev-vpc"
}

module "firewall" {

  source         = "../modules/firewall"
  firewall_name  = "allow-ssh-http"
  network        = "dev-vpc"
}

module "vm" {

  source           = "../modules/vm"

  instance_count   = 2
  instance_name    = "dev-server"
  machine_type     = "e2-medium"
  zone             = var.zone
  network          = "dev-vpc"
  public_key_path  = "~/.ssh/id_rsa.pub"
}
