terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider for general use (if needed)
provider "aws" {
  region = var.aws_region_virginia
}

# Explicit aliased provider for Virginia
provider "aws" {
  alias  = "virginia"
  region = var.aws_region_virginia
}

# Explicit aliased provider for Ohio
provider "aws" {
  alias  = "ohio"
  region = var.aws_region_ohio
}

# ==========================================
# VPC & SUB-NETWORKING (Virginia Region)
# ==========================================

# Expanded CIDR block from /24 to /16 to avoid subnet sizing conflicts
resource "aws_vpc" "virginia_cloud" {
  provider   = aws.virginia
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Virginia-Cloud"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.virginia
  vpc_id   = aws_vpc.virginia_cloud.id

  tags = {
    Name = "Virginia-IGW"
  }
}

resource "aws_subnet" "public_subnet" {
  provider                = aws.virginia
  vpc_id                  = aws_vpc.virginia_cloud.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  provider                = aws.virginia
  vpc_id                  = aws_vpc.virginia_cloud.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet"
  }
}

# ==========================================
# NAT GATEWAY COMPONENTS (For Private Subnet)
# ==========================================

resource "aws_eip" "nat_eip" {
  provider   = aws.virginia
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "private_to_nat" {
  provider      = aws.virginia
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id # Must be placed in a public subnet

  tags = {
    Name = "Virginia-NAT-Gateway"
  }
}

# ==========================================
# ROUTING INFRASTRUCTURE
# ==========================================

# Public Routing Layout
resource "aws_route_table" "public_rtw" {
  provider = aws.virginia
  vpc_id   = aws_vpc.virginia_cloud.id

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route" "public_route" {
  provider               = aws.virginia
  route_table_id         = aws_route_table.public_rtw.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  provider       = aws.virginia
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rtw.id
}

# Private Routing Layout
resource "aws_route_table" "private_rtw" {
  provider = aws.virginia
  vpc_id   = aws_vpc.virginia_cloud.id

  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route" "private_route" {
  provider               = aws.virginia
  route_table_id         = aws_route_table.private_rtw.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_to_nat.id
}

resource "aws_route_table_association" "private_assoc" {
  provider       = aws.virginia
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rtw.id
}






# ==========================================
# VPC & SUB-NETWORKING (Ohio Region)
# ==========================================

# Expanded CIDR block from /24 to /16 to avoid subnet sizing conflicts
resource "aws_vpc" "ohio_cloud" {
  provider   = aws.ohio
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Ohio-Cloud"
  }
}

resource "aws_internet_gateway" "igw_ohio" {
  provider = aws.ohio
  vpc_id   = aws_vpc.ohio_cloud.id

  tags = {
    Name = "Ohio -IGW"
  }
}

resource "aws_subnet" "public_subnet_ohio" {
  provider                = aws.ohio
  vpc_id                  = aws_vpc.ohio_cloud.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "private_subnet_ohio" {
  provider                = aws.ohio
  vpc_id                  = aws_vpc.ohio_cloud.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private-Subnet"
  }
}

# ==========================================
# NAT GATEWAY COMPONENTS (For Private Subnet)
# ==========================================

resource "aws_eip" "nat_eip_ohio" {
  provider   = aws.ohio
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw_ohio]
}

resource "aws_nat_gateway" "private_to_nat_ohio" {
  provider      = aws.ohio
  allocation_id = aws_eip.nat_eip_ohio.id
  subnet_id     = aws_subnet.public_subnet_ohio.id

  tags = {
    Name = "Ohio-NAT-Gateway"
  }
}



# ==========================================
# ROUTING INFRASTRUCTURE
# ==========================================

# Public Routing Layout
resource "aws_route_table" "public_rtw_ohio" {
  provider = aws.ohio
  vpc_id   = aws_vpc.ohio_cloud.id

  tags = {
    Name = "Public-Route-Table-Ohio"
  }
}

resource "aws_route" "public_route_ohio" {
  provider               = aws.ohio
  route_table_id         = aws_route_table.public_rtw_ohio.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_ohio.id
}

resource "aws_route_table_association" "public_assoc_ohio" {
  provider       = aws.ohio
  subnet_id      = aws_subnet.public_subnet_ohio.id
  route_table_id = aws_route_table.public_rtw_ohio.id
}

# Private Routing Layout
resource "aws_route_table" "private_rtw_ohio" {
  provider = aws.ohio
  vpc_id   = aws_vpc.ohio_cloud.id

  tags = {
    Name = "Private-Route-Table-Ohio"
  }
}

resource "aws_route" "private_route_ohio" {
  provider               = aws.ohio
  route_table_id         = aws_route_table.private_rtw_ohio.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_to_nat_ohio.id
}

resource "aws_route_table_association" "private_assoc_ohio" {
  provider       = aws.ohio
  subnet_id      = aws_subnet.private_subnet_ohio.id
  route_table_id = aws_route_table.private_rtw_ohio.id
}



# ==========================================
# COMPUTE INSTANCES (EC2)
# ==========================================

# Default instance configuration
resource "aws_instance" "terraform_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  user_data     = file("${path.module}/scripts/terraform_runner.sh")

  tags = {
    Name = "Terraform-Server"
  }
}

# Explicitly assigned to the Virginia Provider
resource "aws_instance" "north_virginia_public" {
  provider      = aws.virginia
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  user_data     = file("${path.module}/scripts/web.sh")


  tags = {
    Name = "Virginia-Server-pub"
  }
}

resource "aws_instance" "north_virginia_private" {
  provider      = aws.virginia
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet.id
  user_data     = file("${path.module}/scripts/database.sh")

  tags = {
    Name = "Virginia-Server-pvt"
  }
}

# Explicitly assigned to the Ohio Provider
resource "aws_instance" "ohio_public" {
  provider      = aws.ohio
  ami           = var.ami_id_ohio
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_ohio.id
  user_data     = file("${path.module}/scripts/web.sh")
  tags = {
    Name = "Ohio-Server-pub"
  }
}

resource "aws_instance" "ohio_private" {
  provider      = aws.ohio
  ami           = var.ami_id_ohio
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet_ohio.id
  user_data     = file("${path.module}/scripts/database.sh")

  tags = {
    Name = "Ohio-Server-pvt"
  }
}
