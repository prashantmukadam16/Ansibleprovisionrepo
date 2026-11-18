project_id       = "project-88c619e6-27a3-4887-94b"
region           = "us-central1"
zone             = "us-central1-a"
machine_type     = "e2-medium"
instance_count   = 2
name_prefix      = "ansible-dev"
ssh_source_ranges = ["203.0.113.10/32"] # CHANGE to your Jenkins agent/admin public IP CIDR
