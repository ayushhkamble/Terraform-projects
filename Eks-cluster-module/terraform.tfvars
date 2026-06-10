region = "eu-north-1"

cluster_name = "my-eks-cluster"

kubernetes_version = "1.36"

vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

instance_types = ["c7i-flex.large"]

node_desired_size = 2
node_min_size     = 1
node_max_size     = 3