terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.42"
    }
  }
}

provider "volterra" {
  timeout = "90s"
  # api_p12_file = "./training.console.ves.volterra.io.api-creds.p12"
  url = "https://training-dev.console.ves.volterra.io/api"
}

provider "aws" {
  region = local.region
}
