terraform {

  backend "gcs" {
    bucket = "terraform-state-prod"
    prefix = "terraform/prod"
  }
}
