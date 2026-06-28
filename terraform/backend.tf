terraform {
  backend "s3" {
    bucket = "spot-render-tfstate"
    key    = "envs/dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
