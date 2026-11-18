resource "google_compute_instance" "vm_instance" {
  count        = var.instance_count
  name         = "${var.instance_name}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = var.network
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_username}:${trimspace(var.ssh_public_key)}"
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -eux
    apt-get update
    apt-get install -y python3
  SCRIPT

  labels = var.labels
}
