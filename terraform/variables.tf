variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Project name prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
}

variable "az_count" {
  type        = number
  description = "How many AZs to span"
  default     = 3
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "node_groups" {
  description = "Node group definitions"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
  }))
}

variable "input_bucket" {
  type        = string
  description = "Name for input bucket"
}

variable "output_bucket" {
  type        = string
  description = "Name for output bucket"
}

variable "error_bucket" {
  type        = string
  description = "Name for error bucket"
}

variable "retention_days" {
  type        = number
  description = "Retention in days for lifecycle rules"
  default     = 30
}

variable "secrets" {
  description = "Map of secrets to create"
  type        = map(string)
  default     = {}
}

variable "domain" {
  type        = string
  description = "Primary domain for ingress"
}

variable "enable_gpu_node_group" {
  type        = bool
  description = "Enable GPU node group for Ollama"
  default     = false
}

variable "gpu_instance_type" {
  type        = string
  description = "EC2 instance type for GPU node group"
  default     = "g4dn.xlarge"
}

variable "gpu_min_size" {
  type        = number
  description = "Minimum size for GPU node group"
  default     = 0
}

variable "gpu_max_size" {
  type        = number
  description = "Maximum size for GPU node group"
  default     = 2
}

variable "gpu_desired_size" {
  type        = number
  description = "Desired size for GPU node group"
  default     = 1
}

variable "gpu_count" {
  type        = number
  description = "Number of GPUs per instance"
  default     = 1
}
