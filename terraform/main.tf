provider "aws" {
  region = "us-east-1"
}

# ==========================================
# 1. NETWORKING (Required for Kubernetes)
# ==========================================
resource "aws_vpc" "ml_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "ml-eks-vpc" }
}

# EKS requires at least 2 subnets in DIFFERENT Availability Zones
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags              = { Name = "ml-public-1", "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags              = { Name = "ml-public-2", "kubernetes.io/role/elb" = "1" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ml_vpc.id
  tags   = { Name = "ml-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ml_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# 2. S3 BUCKET (Model Registry)
# ==========================================
resource "aws_s3_bucket" "model_registry" {
  bucket        = "ml-model-registry-store-2026"
  force_destroy = false
}

# ==========================================
# 3. IAM ROLES (Permissions for Kubernetes)
# ==========================================
# Role for the EKS Cluster control plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "ml-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Role for the worker nodes (the actual servers running your apps)
resource "aws_iam_role" "eks_node_role" {
  name = "ml-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# ==========================================
# 4. THE KUBERNETES CLUSTER (AWS EKS)
# ==========================================
resource "aws_eks_cluster" "ml_cluster" {
  name     = "ml-production-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Node Group (The actual servers inside your cluster)
resource "aws_eks_node_group" "ml_nodes" {
  cluster_name    = aws_eks_cluster.ml_cluster.name
  node_group_name = "ml-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  # CHANGE THIS: Changed from t3.medium to a Free Tier eligible instance type
  instance_types = ["t3.micro"] 

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_registry,
  ]
}
