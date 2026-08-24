# Intellipaat Final Project

## Architecture

![AWS multi-region architecture](assets/Architecture.png)

This project provisions a small multi-region AWS environment with Terraform:

- **North Virginia (`us-east-1`)** and **Ohio (`us-east-2`)** are managed through separate AWS provider aliases.
- Each region contains a VPC with public and private subnets.
- Internet gateways provide public subnet connectivity, while NAT gateways allow private subnet instances to reach the internet for package installation without exposing them directly.
- Public EC2 instances run the web server setup, and private EC2 instances run the database setup.
- AMI IDs are configurable independently for Virginia and Ohio through `terraform.tfvars`, which allows region-specific AMIs.

## Architectural Decisions

### One Terraform configuration for the whole environment

Instead of creating and maintaining a separate Terraform server or separate infrastructure configuration for each region, the deployment is defined in one Terraform configuration. Provider aliases let the same configuration create resources in both regions while keeping each resource explicitly associated with the correct region.

### One automation script for the Terraform host

The Terraform host is created as part of the same infrastructure automation. Its bootstrap process is defined in the single `scripts/terraform_runner.sh` script, which installs the tools required to run Terraform. This avoids creating a separate server setup process and keeps the host provisioning repeatable.

The web and database EC2 instances still use their purpose-specific bootstrap scripts, `scripts/web.sh` and `scripts/database.sh`, so each application role receives only its required software.

### Public and private network separation

Web instances are placed in public subnets so they can receive internet traffic. Database instances are placed in private subnets and use the NAT gateway only for outbound updates and package installation. This reduces direct exposure of the database tier.

## Project Files

- `main.tf` - AWS providers, networking, NAT gateways, routes, and EC2 instances.
- `var.tf` - Terraform input variable definitions.
- `terraform.tfvars` - Region-specific AMI values.
- `scripts/terraform_runner.sh` - Terraform host bootstrap script.
- `scripts/web.sh` - Nginx installation script.
- `scripts/database.sh` - MySQL installation script.

## Usage

1. Set valid region-specific AMI IDs in `terraform.tfvars`.
2. Initialize Terraform:

	```bash
	terraform init
	```

3. Review the deployment plan:

	```bash
	terraform plan
	```

4. Apply the infrastructure:

	```bash
	terraform apply
	```

5. Remove the resources when finished:

	```bash
	terraform destroy
	```
