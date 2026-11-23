variable "instance_count" {
  description = "Number of web instances."
  type        = number
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 5
    error_message = "instance_count must be between 1 and 5."
  }
}

variable "instance_name" {
  type = string
}
variable "machine_type" {
  type = string
}
variable "zone" {
  type = string
}
variable "network" {
  type = string
}
variable "network_tags" {
  type = list(string)
}
variable "ssh_username" {
  type = string
}
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "boot_image" {
  type    = string
  default = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}
variable "boot_disk_size_gb" {
  type    = number
  default = 20
}
variable "labels" {
  type    = map(string)
  default = { managed_by = "terraform", workload = "ansible-web" }
}
