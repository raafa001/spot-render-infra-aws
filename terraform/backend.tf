terraform {
  backend "s3" {
    bucket = "spot-render-tfstate"
    key    = "envs/dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }

  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
