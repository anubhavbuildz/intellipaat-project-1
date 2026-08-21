terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias = "virgina"
  region = var.aws_region
}

provider "aws" {
  alias = "ohio"
  region = var.aws_region
}

resource "aws_instance" "terraform_server" {
  ami  = var.ami_id
  instance_type = var.instance_type
  user_data = file("${path.module}/scripts/terraform.sh")
  tags = {
    Name="Terraform-Server"
  }
}



resource "aws_vpc" "virginia_cloud" {
     cidr_block = "10.0.0.0/24"
     


     tags = {
       "Name" = "Virginia-Cloud" 
     }
  
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.virginia_cloud.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

resource "" "name" {
  
}

resource "aws_instance" "north_virgina" {
  ami  = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Terraform-Server" 
  }
}

resource "aws_instance" "ohio" {
  ami  = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Terraform-Server" 
  }
}