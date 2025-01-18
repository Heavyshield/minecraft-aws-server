# Terraform Minecraft Server

This Terraform configuration creates an AWS EC2 t2.small instance set up for running a Minecraft server. Based on AWS Blog https://aws.amazon.com/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/

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

2. Create a `terraform.tfvars` file with your SSH key name:
```hcl
key_name = "your-key-name"
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
- EC2 t2.small instance
- Required networking components

## Verify everything went well

- SSH instance (ssh -i your-key-pair.pem ec2-user@your-instance-ip)
- cd /opt/minecraft/server/ 

## Operate server
- sudo ./stop
- sudo ./start


## Note

After the infrastructure is created, you'll need to:
1. SSH into the instance
2. Install Java
3. Set up and configure the Minecraft server

The server's public IP will be displayed in the outputs.