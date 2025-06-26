terraform {
    required_providers {
        aws  = {
            source = "hashicorp/aws"
            version = "~> 4.67"
        }
    }

    required_version = "~> 1.5.0"
  
}

provider "aws" {
  region = var.aws_region
}

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-${var.app_environment}-sg"
  description = "Security group for FastAPI application"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
  
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "FastAPI"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}-sg"
  }
}

# EC2 instance for FastAPI
resource "aws_instance" "app_server" {
  ami                    = "ami-001b3fc6186c63470" 
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y python3 python3-pip
              sudo pip3 install fastapi uvicorn
              
              # Create app directory
              mkdir -p /app
              
              # Create FastAPI application file
              cat > /app/app.py << 'EOL'
              from fastapi import FastAPI 
              app=FastAPI()

              @app.get("/")
              def home_route():
                  return {"message":"this is home route"}

              @app.get("/greet")
              def greet_route():
                  return {"data":"hello world"}
              EOL
              
              # Run the application
              nohup uvicorn app:app --host 0.0.0.0 --port 8000 --app-dir /app > /app/fastapi.log 2>&1 &
              EOF
  
  tags = {
    Name = "${var.app_name}-${var.app_environment}"
  }
}

# Create a key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "${var.app_name}-deployer-key"
  public_key = file("~/.ssh/id_rsa.pub") # You'll need to replace this with your actual public key path
}