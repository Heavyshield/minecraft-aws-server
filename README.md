# Terraform Minecraft Server

This Terraform configuration sets up all the necessary AWS infrastructure to run a Minecraft server. It primarily consists of a t4g.small EC2 instance (2 GB of RAM and 2 vCPUs) and the associated networking resources required to make the server accessible from outside AWS (VPC, Subnet, Internet Gateway, etc.).

This setup is inspired by the AWS blog post: Setting Up a Minecraft Java Server on Amazon EC2. https://aws.amazon.com/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/

## Why this project ?

When exploring Minecraft server hosting solutions, you'll find many options available. While they are often user-friendly, their pricing can be problematic. It’s difficult to find hosting for under $10/month, and even then, performance may be limited (e.g., 1 GB RAM and 1 vCPU).

Paying ~$10/month to play solo or with a small group of friends seems excessive, especially if the server isn't actively used every month. You’ll still incur monthly charges regardless of usage.

This project demonstrates how cloud technologies and Infrastructure as Code (IaC) can offer a cost-effective, customizable solution for hosting a Minecraft server with minimal effort for deployment and maintenance.

## Expected costs (calculated in Q1 2025)
Some quick caluclation from aws calculator with 3 scenarios

### 100 % uptime
- Estimated Cost: $17/month

This assumes the server is running 24/7.

### 40h per month uptime
- Estimated Cost: $4/month

This is ideal for most users, requiring you to manually stop the EC2 instance after each gaming session.

### 40h per month uptime and no Elastic Ip
- Estimated Cost: $0.75/month

For the most cost-conscious users, removing the Elastic IP reduces costs further. However, you’ll need to update the server’s IP address every time the instance restarts.

## Prerequisites

- AWS account
- Terraform installed
- AWS CLI configured with appropriate credentials
- SSH key pair created in AWS (do not forget to chmod 400 mykey.pem)

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Create a `variables.tf` file with this structure + your owns parameters:
```
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = <AWS_REGION>
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks for SSH access"
  type        = list(string)
  default     = [<YOUR_IP>]
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  # Amazon Linux 2 AMI - adjust this value based on your region
  default     = "ami-0735c191cf914754d"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = <KEY_PAIR_NAME>
}
```

3. Review the planned changes:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

5. When finished, destroy the infrastructure:
```bash
terraform destroy
```

## Infrastructure Created

- VPC with a public subnet
- Internet Gateway
- Route Table
- Security Group (allows Minecraft port 25565 and SSH port 22)
- EC2 t4g.small instance
- Required networking components

## Verify everything went well

- SSH instance (ssh -i your-key-pair.pem ec2-user@your-instance-ip)
- cd /opt/minecraft/server/ 

## Operate server

- sudo ./stop
- sudo ./start

## Next steps
- Implement user-data scripts to manage modded versions (e.g., DawnCraft).
- Automate EC2 stop behavior, likely using a Lambda function with a schedule.
- Set up a trigger to start the server, such as via SMS or email.
- Add backup functionality to preserve server data.

## Contributor

Thibaud Lasserre