resource "google_compute_firewall" "allow_ssh_http" {

  name    = var.firewall_name
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
}
