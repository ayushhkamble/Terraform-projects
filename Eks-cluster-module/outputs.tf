output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "node_group_name" {
  value = module.nodegroup.node_group_name
}