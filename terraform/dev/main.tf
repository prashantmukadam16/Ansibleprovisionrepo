module "network" {
  source       = "../modules/network"
  network_name = "${var.name_prefix}-vpc"
}

module "firewall" {
  source         = "../modules/firewall"
  firewall_name  = "${var.name_prefix}-allow-web-ssh"
  network        = module.network.network_name
  ssh_source_ranges = var.ssh_source_ranges
  network_tags   = ["${var.name_prefix}-web"]
}

module "vm" {
  source          = "../modules/vm"
  instance_count  = var.instance_count
  instance_name   = "${var.name_prefix}-web"
  machine_type    = var.machine_type
  zone            = var.zone
  network         = module.network.network_self_link
  network_tags    = ["${var.name_prefix}-web"]
  ssh_username    = var.ssh_username
  ssh_public_key  = var.ssh_public_key
}
