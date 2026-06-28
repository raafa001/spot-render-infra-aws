region        = "us-east-1"
name          = "spot-render"
vpc_cidr      = "10.0.0.0/16"
az_count      = 3
cluster_name  = "spot-render-dev"
node_groups = {
  api = {
    instance_type = "t3.large"
    min_size      = 1
    max_size      = 3
    desired_size  = 2
  }
  workers = {
    instance_type = "g5.xlarge"
    min_size      = 0
    max_size      = 5
    desired_size  = 1
  }
}
input_bucket  = "spot-render-input-dev"
output_bucket = "spot-render-output-dev"
error_bucket  = "spot-render-error-dev"
domain        = "dev.spotrender.example.com"
