terraform {
  backend "gcs" {
    bucket = "terraform-bucketudx-dev"
    prefix = "terraform/dev"
  }
}
