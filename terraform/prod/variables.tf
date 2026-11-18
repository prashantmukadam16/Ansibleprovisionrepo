variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "machine_type" {
  type = string
}
variable "instance_count" {
  type    = number
  default = 2
}
variable "name_prefix" {
  type    = string
  default = "ansible-prod"
}
variable "ssh_username" {
  type    = string
  default = "ubuntu"
}
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "ssh_source_ranges" {
  description = "Replace with the public IP/CIDR of the Jenkins agent or trusted admin network."
  type        = list(string)
  validation {
    condition     = length(var.ssh_source_ranges) > 0 && !contains(var.ssh_source_ranges, "0.0.0.0/0")
    error_message = "Provide at least one trusted SSH CIDR; 0.0.0.0/0 is not allowed."
  }
}
