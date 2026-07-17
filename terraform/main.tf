provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  name       = var.name
  cidr_block = var.vpc_cidr
  az_count   = var.az_count
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets
  node_groups  = var.node_groups
}

module "s3" {
  source = "./modules/s3-buckets"

  project        = var.name
  input_bucket   = var.input_bucket
  output_bucket  = var.output_bucket
  error_bucket   = var.error_bucket
  retention_days = var.retention_days
}

module "secrets" {
  source = "./modules/secrets"

  project = var.name
  secrets = var.secrets
}

module "irsa" {
  source = "./modules/irsa"

  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  service_accounts = {
    api    = { namespace = "spot-render",  bucket_arn = module.s3.input_bucket_arn }
    portal = { namespace = "spot-render",  bucket_arn = module.s3.input_bucket_arn }
    worker = { namespace = "rendering",     bucket_arn = module.s3.output_bucket_arn }
  }
}

module "ingress_waf" {
  source = "./modules/ingress-waf"

  cluster_name = module.eks.cluster_name
  domain       = var.domain
}

module "gpu_node_group" {
  count = var.enable_gpu_node_group ? 1 : 0

  source = "./modules/gpu-node-group"

  cluster_name    = module.eks.cluster_name
  cluster_arn     = module.eks.cluster_arn
  node_group_name = "${var.name}-gpu"
  node_role_arn   = module.eks.node_role_arn
  subnets         = module.vpc.private_subnets
  instance_type   = var.gpu_instance_type
  min_size        = var.gpu_min_size
  max_size        = var.gpu_max_size
  desired_size    = var.gpu_desired_size
  gpu_count       = var.gpu_count
}

resource "aws_iam_role_policy_attachment" "nvidia_plugin" {
  for_each = var.enable_gpu_node_group ? toset(["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy", "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AWSMarketplaceGetEntitlements"]) : toset([])

  policy_arn = each.value
  role       = module.eks.node_role_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

output "s3_buckets" {
  value = {
    input  = module.s3.input_bucket_name
    output = module.s3.output_bucket_name
    error  = module.s3.error_bucket_name
  }
}
