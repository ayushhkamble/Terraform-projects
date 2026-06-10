resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn

  # IMPORTANT: These must be public subnet IDs
  subnet_ids = var.subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  tags = {
    Name = var.node_group_name
  }
}