terraform {
  required_version = "~> 1.10.0"
  backend "s3" {
    bucket = "tsanghan-tfstate"
    key    = "f5xc-cicd.tfstate"
    region = "ap-southeast-1"
  }
}