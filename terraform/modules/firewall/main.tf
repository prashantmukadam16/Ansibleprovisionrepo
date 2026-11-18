resource "google_compute_firewall" "web_ingress" {
  name      = var.firewall_name
  network   = var.network
  direction = "INGRESS"
  priority  = 1000
  target_tags = var.network_tags

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ssh_ingress" {
  name      = "${var.firewall_name}-ssh"
  network   = var.network
  direction = "INGRESS"
  priority  = 1000
  target_tags = var.network_tags

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
}
