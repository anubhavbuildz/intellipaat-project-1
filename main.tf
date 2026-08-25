terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.bootstrap_region
}

resource "aws_vpc" "bootstrap" {
  cidr_block = "10.254.0.0/16"

  tags = {
    Name = "Terraform-Bootstrap-VPC"
  }
}

resource "aws_internet_gateway" "bootstrap" {
  vpc_id = aws_vpc.bootstrap.id
}

resource "aws_subnet" "bootstrap" {
  vpc_id                  = aws_vpc.bootstrap.id
  cidr_block              = "10.254.1.0/24"
  availability_zone       = "${var.bootstrap_region}a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "bootstrap" {
  vpc_id = aws_vpc.bootstrap.id
}

resource "aws_route" "bootstrap_internet" {
  route_table_id         = aws_route_table.bootstrap.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bootstrap.id
}

resource "aws_route_table_association" "bootstrap" {
  subnet_id      = aws_subnet.bootstrap.id
  route_table_id = aws_route_table.bootstrap.id
}

resource "aws_security_group" "bootstrap" {
  name        = "terraform-bootstrap"
  description = "Allow the Terraform runner outbound access"
  vpc_id      = aws_vpc.bootstrap.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "archive_file" "infrastructure" {
  type        = "zip"
  source_dir  = "${path.module}/infrastructure"
  output_path = "${path.module}/infrastructure.zip"
  excludes    = [".terraform", "*.tfstate", "*.tfstate.*"]
}

resource "aws_s3_bucket" "infrastructure" {
  bucket_prefix = "terraform-infrastructure-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "infrastructure" {
  bucket                  = aws_s3_bucket.infrastructure.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "infrastructure" {
  bucket = aws_s3_bucket.infrastructure.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.infrastructure.arn,
        "${aws_s3_bucket.infrastructure.arn}/*"
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

resource "aws_s3_object" "infrastructure" {
  bucket = aws_s3_bucket.infrastructure.id
  key    = "infrastructure.zip"
  source = data.archive_file.infrastructure.output_path
  etag   = data.archive_file.infrastructure.output_md5
}

resource "aws_iam_role" "terraform_runner" {
  name = "terraform-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_runner" {
  name = "terraform-runner-infrastructure-access"
  role = aws_iam_role.terraform_runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.infrastructure.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "terraform_runner" {
  name = "terraform-runner-profile"
  role = aws_iam_role.terraform_runner.name
}

resource "aws_instance" "terraform_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.bootstrap.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bootstrap.id]
  iam_instance_profile        = aws_iam_instance_profile.terraform_runner.name
  user_data = templatefile("${path.module}/scripts/terraform_runner.sh", {
    bucket = aws_s3_bucket.infrastructure.id
    key    = aws_s3_object.infrastructure.key
    region = var.bootstrap_region
  })

  depends_on = [aws_iam_role_policy_attachment.terraform_admin]

  tags = {
    Name = "Terraform-Server"
  }
}

output "terraform_server_public_ip" {
  description = "Public IP address of the Terraform runner"
  value       = aws_instance.terraform_server.public_ip
}

output "infrastructure_bucket" {
  description = "S3 bucket containing the child Terraform configuration"
  value       = aws_s3_bucket.infrastructure.id
}
