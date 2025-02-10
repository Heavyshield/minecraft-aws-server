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

# Lambda role and policy for EC2 start/stop
resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda_ec2_start_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to start/stop EC2 instances
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_start_stop_policy"
  role = aws_iam_role.lambda_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function for EC2 start/stop
resource "aws_lambda_function" "ec2_start_stop" {
  filename         = "src/lambda_function.zip"
  function_name    = "ec2_start_stop"
  role            = aws_iam_role.lambda_ec2_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("src/lambda_function.zip")
  runtime         = "python3.10"
  timeout         = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.minecraft_server.id
    }
  }
}

resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda_policy" {
  name = "scheduler-invoke-lambda-policy"
  role = aws_iam_role.scheduler_invoke_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.ec2_start_stop.arn
        ]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "daily_lambda_trigger" {
  name                = "daily-ec2-stop"
  schedule_expression = "cron(0 2 * * ? *)"
  
  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.ec2_start_stop.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

# Create EC2 Instance
resource "aws_iam_role" "minecraft_server_role" {
  name = "minecraft-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.minecraft_bucket.arn,
          "${aws_s3_bucket.minecraft_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "minecraft_server_profile" {
  name = "minecraft-server-profile"
  role = aws_iam_role.minecraft_server_role.name
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-0eddb054af3138dc5"
  instance_type = "t4g.small"
  subnet_id     = aws_subnet.minecraft_subnet.id

  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  key_name              = var.key_name
  user_data_base64      = base64encode(file("${path.module}/user-data.txt"))
  iam_instance_profile  = aws_iam_instance_profile.minecraft_server_profile.name

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
  vpc      = true
}

# Create S3 bucket with random name
resource "aws_s3_bucket" "minecraft_bucket" {
  bucket = var.bucket_name
  
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.minecraft_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}