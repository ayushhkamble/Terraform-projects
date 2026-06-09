variable "region" {
  description = "AWS Region"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDRs"
  type        = list(string)
}

variable "instance_types" {
  description = "Node Group Instance Types"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired Node Count"
  type        = number
}

variable "node_min_size" {
  description = "Minimum Node Count"
  type        = number
}

variable "node_max_size" {
  description = "Maximum Node Count"
  type        = number
}