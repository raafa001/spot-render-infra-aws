region        = "us-east-1"
name          = "spot-render"
vpc_cidr      = "10.1.0.0/16"
az_count      = 3
cluster_name  = "spot-render-prod"
node_groups = {
  api = {
    instance_type = "m6i.large"
    min_size      = 2
    max_size      = 6
    desired_size  = 3
  }
  workers = {
    instance_type = "g5.2xlarge"
    min_size      = 1
    max_size      = 10
    desired_size  = 2
  }
}
input_bucket  = "spot-render-input-prod"
output_bucket = "spot-render-output-prod"
error_bucket  = "spot-render-error-prod"
domain        = "spotrender.example.com"
