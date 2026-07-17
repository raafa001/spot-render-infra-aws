variable "cluster_name" {}
variable "cluster_arn" {}
variable "node_group_name" {}
variable "node_role_arn" {}
variable "subnets" {}
variable "instance_type" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_size" {}
variable "ami_type" {
  default = "AL2_x86_64_GPU"
}
variable "disk_size" {
  default = 100
}
variable "gpu_count" {
  default = 1
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnets
  ami_type        = var.ami_type
  disk_size       = var.disk_size

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = [var.instance_type]

  lifecycle {
    create_before_destroy = true
  }

  taint {
    key    = "spot.ai/nodetype"
    value  = "gpu"
    effect = "NO_SCHEDULE"
  }

  label = {
    "spot.ai/nodetype" = "gpu"
    "nvidia.com/gpu"   = var.gpu_count
  }
}

output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  value = aws_eks_node_group.this.arn
}
