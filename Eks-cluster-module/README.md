# Create Amazon EKS Cluster from EC2 Instance Using Terraform Modules

## Project Objective

In this project, we will create an **Amazon EKS Kubernetes Cluster** from an **Ubuntu EC2 instance** using **Terraform modules**.

We will create:

* VPC
* Public subnets
* Private subnets
* Internet Gateway
* NAT Gateway
* IAM roles
* EKS cluster
* EKS managed node group
* kubectl connection
* Test Nginx application

---

## 1. Introduction

## What is Amazon EKS?

Amazon EKS means **Elastic Kubernetes Service**.

It is a managed Kubernetes service provided by AWS.
AWS manages the Kubernetes control plane, and we manage the worker nodes and applications.

---

## What is Terraform?

Terraform is an **Infrastructure as Code** tool.

Using Terraform, we can create AWS resources using `.tf` configuration files instead of creating everything manually from the AWS Console.

---

## What is a Terraform Module?

A Terraform module is a reusable folder that contains Terraform code.

In this project, we use separate modules for:

* VPC
* IAM
* EKS cluster
* Node group

This makes the project clean and easy to manage.

---

## Why use EC2 as a Terraform Management Server?

We use an EC2 instance because:

* It runs inside AWS
* It can access AWS services easily
* We can install Terraform, AWS CLI, kubectl, and eksctl
* We can manage the EKS cluster from one server

---

## EKS Cluster vs Node Group

| Component   | Meaning                                 |
| ----------- | --------------------------------------- |
| EKS Cluster | Kubernetes control plane managed by AWS |
| Node Group  | EC2 worker nodes where pods run         |

---

# 2. Architecture

```text
User
  |
  v
SSH into Ubuntu EC2 Instance
  |
  v
Install AWS CLI, Terraform, kubectl, eksctl
  |
  v
Configure AWS Credentials
  |
  v
Run Terraform Code
  |
  v
Terraform Creates VPC
  |
  v
Terraform Creates IAM Roles
  |
  v
Terraform Creates EKS Cluster
  |
  v
Terraform Creates Worker Node Group
  |
  v
kubectl Connects to EKS
  |
  v
Verify Nodes and Pods
```

---

# 3. Prerequisites

Before starting, you need:

* AWS account
* Ubuntu EC2 instance
* SSH key pair
* IAM user or IAM role with required permissions
* Internet access
* Basic Terraform knowledge

---

# 4. Step 1: Launch Ubuntu EC2 Instance

Create one Ubuntu EC2 instance.

Recommended settings:

| Option         | Value                     |
| -------------- | ------------------------- |
| AMI            | Ubuntu Server             |
| Instance Type  | t3.micro or t3.small      |
| Key Pair       | Select or create key pair |
| Security Group | Allow SSH port 22         |
| Storage        | 20 GB or more             |

Security group rule:

```text
Type: SSH
Port: 22
Source: My IP
```

---

# 5. Step 2: Connect to EC2 Instance

Use this command from your local system:

```bash
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

Example:

```bash
ssh -i eks-key.pem ubuntu@13.60.10.25
```

---

# 6. Step 3: Install Required Tools

## Update System

```bash
sudo apt update -y
sudo apt upgrade -y
```

Install basic packages:

```bash
sudo apt install -y unzip curl wget git gnupg software-properties-common
```

---

## Install AWS CLI Latest Version

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Check version:

```bash
aws --version
```

---

## Install Terraform Latest Version

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install terraform -y
```

Check version:

```bash
terraform version
```

---

## Install kubectl Latest Stable Version

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

Check version:

```bash
kubectl version --client
```

---

## Install eksctl Latest Version

```bash
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

Check version:

```bash
eksctl version
```

---

# 7. Step 4: Configure AWS CLI

Run:

```bash
aws configure
```

Enter:

```text
AWS Access Key ID: your-access-key
AWS Secret Access Key: your-secret-key
Default region name: eu-north-1
Default output format: json
```

Check AWS connection:

```bash
aws sts get-caller-identity
```

Better option:

Use an **IAM Role attached to EC2** instead of access keys.

---

# 8. Step 5: Create Project Structure

```bash
mkdir eks-terraform-project
cd eks-terraform-project
```

```bash
mkdir -p modules/vpc modules/iam modules/eks modules/nodegroup
```

```bash
touch main.tf provider.tf variables.tf terraform.tfvars outputs.tf
```

```bash
touch modules/vpc/main.tf modules/vpc/variables.tf modules/vpc/outputs.tf
touch modules/iam/main.tf modules/iam/variables.tf modules/iam/outputs.tf
touch modules/eks/main.tf modules/eks/variables.tf modules/eks/outputs.tf
touch modules/nodegroup/main.tf modules/nodegroup/variables.tf modules/nodegroup/outputs.tf
```

Final structure:

```text
eks-terraform-project/
├── main.tf
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── README.md
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── nodegroup/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

# 9. Root Terraform Files

## provider.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
```

---

## variables.tf

```hcl
variable "region" {
  description = "AWS Region"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
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
  description = "EKS Node Group Instance Types"
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
```

---

## terraform.tfvars

```hcl
region = "eu-north-1"

cluster_name = "my-eks-cluster"

kubernetes_version = "1.35"

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
```

---

## main.tf

```hcl
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
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  depends_on = [module.iam]
}

module "nodegroup" {
  source = "./modules/nodegroup"

  cluster_name      = module.eks.cluster_name
  node_group_name   = "${var.cluster_name}-node-group"
  node_role_arn     = module.iam.eks_node_role_arn
  subnet_ids        = module.vpc.private_subnet_ids
  instance_types    = var.instance_types
  node_desired_size = var.node_desired_size
  node_min_size     = var.node_min_size
  node_max_size     = var.node_max_size

  depends_on = [module.eks]
}
```

---

## outputs.tf

```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "region" {
  value = var.region
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
```

---

# 10. VPC Module

## modules/vpc/variables.tf

```hcl
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
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
```

---

## modules/vpc/main.tf

```hcl
data "aws_availability_zones" "available" {}

resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                           = "${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
    "kubernetes.io/role/internal-elb"                = "1"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
```

---

## modules/vpc/outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}
```

---

# 11. IAM Module

## modules/iam/variables.tf

```hcl
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}
```

---

## modules/iam/main.tf

```hcl
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

---

## modules/iam/outputs.tf

```hcl
output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "eks_cluster_policy_attachment" {
  value = aws_iam_role_policy_attachment.eks_cluster_policy.id
}

output "worker_node_policy_attachment" {
  value = aws_iam_role_policy_attachment.worker_node_policy.id
}

output "cni_policy_attachment" {
  value = aws_iam_role_policy_attachment.cni_policy.id
}

output "ecr_policy_attachment" {
  value = aws_iam_role_policy_attachment.ecr_policy.id
}
```

---

# 12. EKS Module

## modules/eks/variables.tf

```hcl
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes Version"
  type        = string
}

variable "cluster_role_arn" {
  description = "EKS Cluster IAM Role ARN"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS Cluster"
  type        = list(string)
}
```

---

## modules/eks/main.tf

```hcl
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids

    endpoint_private_access = true
    endpoint_public_access  = true
  }
}
```

---

## modules/eks/outputs.tf

```hcl
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}
```

---

# 13. Node Group Module

## modules/nodegroup/variables.tf

```hcl
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "node_group_name" {
  description = "EKS Node Group Name"
  type        = string
}

variable "node_role_arn" {
  description = "EKS Node IAM Role ARN"
  type        = string
}

variable "subnet_ids" {
  description = "Private Subnet IDs for Node Group"
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
```

---

## modules/nodegroup/main.tf

```hcl
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name

  node_role_arn = var.node_role_arn
  subnet_ids    = var.subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
}
```

---

## modules/nodegroup/outputs.tf

```hcl
output "node_group_name" {
  value = aws_eks_node_group.eks_nodes.node_group_name
}

output "node_group_arn" {
  value = aws_eks_node_group.eks_nodes.arn
}
```

---

# 14. Step 11: Run Terraform Commands

## Format Terraform Code

```bash
terraform fmt -recursive
```

This command formats all Terraform files properly.

---

## Initialize Terraform

```bash
terraform init
```

This downloads the required Terraform providers and initializes the project.

---

## Validate Terraform Code

```bash
terraform validate
```

This checks whether the Terraform syntax is correct or not.

---

## Check Terraform Plan

```bash
terraform plan
```

This shows what Terraform will create before applying changes.

---

## Apply Terraform Code

```bash
terraform apply
```

Type:

```text
yes
```

Terraform will start creating AWS resources.

---

# 15. Step 12: Connect kubectl to EKS Cluster

After cluster creation, run:

```bash
aws eks update-kubeconfig --region eu-north-1 --name my-eks-cluster
```

This command updates the kubeconfig file and allows kubectl to connect with the EKS cluster.

---

# 16. Step 13: Verify EKS Cluster

Check nodes:

```bash
kubectl get nodes
```

Check all pods:

```bash
kubectl get pods -A
```

Check services:

```bash
kubectl get svc
```

Check cluster information:

```bash
kubectl cluster-info
```

---

# 17. Step 14: Deploy Test Nginx Application

Create file:

```bash
nano nginx-deployment.yaml
```

Add this code:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx-container
          image: nginx:latest
          ports:
            - containerPort: 80
```

Apply deployment:

```bash
kubectl apply -f nginx-deployment.yaml
```

Check pods:

```bash
kubectl get pods
```

---

## Create Nginx Service

Create file:

```bash
nano nginx-service.yaml
```

Add this code:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
```

Apply service:

```bash
kubectl apply -f nginx-service.yaml
```

Check service:

```bash
kubectl get svc
```

Copy the LoadBalancer DNS name and open it in browser.

---

# 18. Step 15: Clean Up Resources

To delete all AWS resources created by Terraform:

```bash
terraform destroy
```

Type:

```text
yes
```

Cleanup is important because EKS, NAT Gateway, LoadBalancer, and EC2 nodes can generate AWS charges.

---

# 19. Troubleshooting

## AWS credentials not configured

Error:

```text
Unable to locate credentials
```

Fix:

```bash
aws configure
```

Or attach IAM role to EC2.

---

## AccessDenied IAM Error

Error:

```text
AccessDenied
```

Fix:

Make sure your IAM user or IAM role has permissions for:

* EKS
* EC2
* IAM
* VPC
* CloudFormation
* Auto Scaling

---

## kubectl command not found

Fix:

```bash
kubectl version --client
```

If not installed, install kubectl again.

---

## eksctl command not found

Fix:

```bash
eksctl version
```

If not installed, install eksctl again.

---

## EKS cluster stuck in creating

Possible reasons:

* Wrong IAM role
* Subnet issue
* Region issue
* AWS service limit issue

Check AWS Console for detailed error.

---

## Node group not joining cluster

Possible reasons:

* Node IAM role missing policies
* Private subnet has no NAT Gateway
* Wrong subnet selection
* Instance type unavailable in selected region

Check:

```bash
kubectl get nodes
```

Also check EKS node group events in AWS Console.

---

## Subnet tagging issue

EKS requires subnet tags.

Public subnet tags:

```hcl
"kubernetes.io/role/elb" = "1"
```

Private subnet tags:

```hcl
"kubernetes.io/role/internal-elb" = "1"
```

Cluster tag:

```hcl
"kubernetes.io/cluster/my-eks-cluster" = "shared"
```

---

## Terraform lock file issue

Fix:

```bash
rm -rf .terraform
terraform init
```

---

## Region mismatch issue

Check your Terraform region:

```hcl
region = "eu-north-1"
```

Check AWS CLI region:

```bash
aws configure get region
```

---

# 20. Best Practices

* Never upload AWS access keys to GitHub
* Do not upload `terraform.tfvars` if it contains sensitive values
* Use IAM Role for EC2 instead of access keys
* Use Terraform modules for clean structure
* Use remote backend like S3 and DynamoDB for production
* Always run `terraform plan` before `terraform apply`
* Destroy unused resources to avoid AWS charges
* Use private subnets for worker nodes
* Use proper naming for all resources

---

# 21. Add .gitignore File

Create file:

```bash
nano .gitignore
```

Add this content:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
*.tfvars
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

Note:

If your `terraform.tfvars` file does not contain sensitive data, you can upload an example file instead:

```bash
cp terraform.tfvars terraform.tfvars.example
```

Then remove real values from `terraform.tfvars.example`.

---

# 22. Useful Commands Summary

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

```bash
aws eks update-kubeconfig --region eu-north-1 --name my-eks-cluster
```

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc
kubectl cluster-info
```

```bash
terraform destroy
```

---

# 23. Final Result

After completing this project:

* Terraform is installed on EC2
* AWS CLI is configured
* VPC is created
* IAM roles are created
* EKS cluster is created
* Managed node group is created
* kubectl is connected to EKS
* Nginx app is deployed on Kubernetes

This project demonstrates how to create an Amazon EKS Kubernetes cluster using Terraform modules from an EC2 management server.
