terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region  = "eu-west-3"
    profile = "default"
    key     = "terraformstatebucket"
    bucket  = "pichou-terraform-bucket-state"
  }
}
