variable "firewall_name" {
  description = "Base name for firewall rules."
  type        = string
}

variable "network" {
  description = "VPC network name or self link."
  type        = string
}

variable "ssh_source_ranges" {
  description = "Trusted CIDR ranges allowed to SSH to instances. Do not use 0.0.0.0/0."
  type        = list(string)
}

variable "network_tags" {
  description = "Network tags targeted by the firewall rules."
  type        = list(string)
}
