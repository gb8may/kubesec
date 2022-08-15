variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "Cluster VPC name"
  default     = "kubeSec-Demo-VPC"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
  default     = "KubeSec-Demo"
}

variable "cluster_version" {
  type        = string
  description = "Cluster version"
  default     = "1.22"
}

variable "wg1_instance_type" {
  type        = string
  description = "Instance type of first worker nodes group"
  default     = "t3.medium"
}

variable "wg1_name" {
  type        = string
  description = "Name of the first worker nodes group"
  default     = "kubesec-node"
}