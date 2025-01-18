terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "minecraft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "minecraft-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name = "minecraft-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "minecraft_subnet" {
  vpc_id                  = aws_vpc.minecraft_vpc.id
  cidr_block              = "10.0.0.0/22"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "minecraft-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name = "minecraft-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "minecraft_rta" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_rt.id
}

# Create Security Group
resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-security-group"
  description = "Security group for Minecraft server"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Minecraft server port"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft-sg"
  }
}

# Create EC2 Instance
resource "aws_instance" "minecraft_server" {
  ami           = "ami-0eddb054af3138dc5"
  instance_type = "t4g.small"
  subnet_id     = aws_subnet.minecraft_subnet.id

  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  key_name              = var.key_name
  user_data_base64      = base64encode(file("${path.module}/user-data.txt"))

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "minecraft-server"
  }
}

# Create Elastic IP Address
resource "aws_eip" "minecraft-eip" {
  instance = aws_instance.minecraft_server.id
  vpc = true
}