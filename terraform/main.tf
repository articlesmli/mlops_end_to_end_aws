provider "aws" {
  region = "us-east-1"
}

# 1. VPC and Subnets (Your network foundation)
resource "aws_vpc" "ml_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ml-platform-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.ml_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "ml-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.ml_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ml-private-subnet"
  }
}

# 2. S3 Bucket (Model Registry)
resource "aws_s3_bucket" "model_registry" {
  bucket        = "ml-model-registry-store-2026"
  force_destroy = false

  tags = {
    Name = "ml-model-registry"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.model_registry.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.model_registry.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. IAM Role for ML Pipeline
resource "aws_iam_role" "ml_execution_role" {
  name = "ml-pipeline-execution-role"

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

# 4. Security Group to allow SSH access
resource "aws_security_group" "ml_sg" {
  name        = "ml-server-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.ml_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ml-server-sg"
  }
}

# 5. Virtual Server (EC2 Instance) AMI Data Source & Instance
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "ml_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ml_sg.id]

  tags = {
    Name = "ml-learning-server"
  }
}

# 6. Internet Gateway (The bridge to the outside world)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ml_vpc.id

  tags = {
    Name = "ml-igw"
  }
}

# 7. Route Table to direct traffic to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ml_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "ml-public-rt"
  }
}

# 8. Connect the Route Table to your Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}