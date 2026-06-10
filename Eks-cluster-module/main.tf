module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  subnet_ids         = module.vpc.public_subnet_ids

  depends_on = [module.iam]
}

module "nodegroup" {
  source = "./modules/nodegroup"

  cluster_name      = module.eks.cluster_name
  node_group_name   = "${var.cluster_name}-public-nodegroup"
  node_role_arn     = module.iam.eks_node_role_arn

  # IMPORTANT: Public subnet IDs used here
  subnet_ids        = module.vpc.public_subnet_ids

  instance_types    = var.instance_types
  node_desired_size = var.node_desired_size
  node_min_size     = var.node_min_size
  node_max_size     = var.node_max_size

  depends_on = [module.eks]
}