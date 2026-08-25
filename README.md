# Intellipaat Final Project

## Architecture

![AWS multi-region architecture](assets/Architecture.png)

This project provisions a small multi-region AWS environment through a two-stage Terraform deployment:

- The bootstrap stage creates a dedicated public VPC for the Terraform runner, an S3 handoff bucket, and an EC2 IAM instance profile.
- The runner installs Terraform and AWS CLI, downloads the child configuration from S3, and applies it automatically.
- The child configuration creates the North Virginia (`us-east-1`) and Ohio (`us-east-2`) VPCs, subnets, NAT gateways, security groups, and application servers.
- Public instances install and start Apache, with HTTP traffic allowed on port 80. Private instances install and start MySQL.

## Architectural Decisions

### Two Terraform configurations

Terraform cannot create an instance and then use that instance to continue the same apply. The root configuration therefore creates only the bootstrap resources. It packages `infrastructure/` into S3, and the runner applies that child configuration after it starts.

The bootstrap Terraform state and child Terraform state are separate. The child state is created on the runner in `/opt/infrastructure`.

### IAM-based handoff

The runner receives an EC2 instance profile rather than hardcoded AWS keys. The role can read the private S3 package and manage the resources defined by the child configuration.

The web and database instances use their purpose-specific bootstrap scripts, `infrastructure/scripts/web.sh` and `infrastructure/scripts/database.sh`.

### Public and private network separation

Web instances are placed in public subnets so they can receive internet traffic. Database instances are placed in private subnets and use the NAT gateway only for outbound updates and package installation. This reduces direct exposure of the database tier.

## Project Files

- `main.tf` - Bootstrap VPC, S3 handoff, IAM role, and Terraform runner.
- `var.tf` - Bootstrap input variable definitions.
- `terraform.tfvars` - Bootstrap runner AMI and instance type.
- `scripts/terraform_runner.sh` - Runner bootstrap, S3 download, and child apply script.
- `infrastructure/main.tf` - Virginia and Ohio VPCs, routing, NAT gateways, security groups, and EC2 instances.
- `infrastructure/var.tf` and `infrastructure/terraform.tfvars` - Child configuration inputs and regional AMI IDs.
- `infrastructure/scripts/web.sh` - Apache installation and startup script.
- `infrastructure/scripts/database.sh` - MySQL installation and startup script.

## Usage

1. Configure AWS credentials locally with permission to create the bootstrap and child resources.
2. Set a valid Ubuntu/Debian AMI ID for the bootstrap runner in `terraform.tfvars`.
3. Set valid region-specific Ubuntu/Debian AMI IDs in `infrastructure/terraform.tfvars`.
4. Deploy the bootstrap stage from the repository root:

	```bash
	terraform init
	terraform apply -auto-approve
	```

5. Wait for the runner to finish. Its cloud-init output is in `/var/log/terraform-runner.log` on the runner. The child configuration is stored on that server in `/opt/infrastructure`.

6. Check the bootstrap output for the runner's public IP:

	```bash
	terraform output terraform_server_public_ip
	```

7. To remove everything, connect to the runner and destroy the child stack first:

	```bash
	ssh <user>@<terraform-server-public-ip>
	cd /opt/infrastructure
	terraform destroy -auto-approve
	```

8. From the repository root, destroy the bootstrap stage:

	```bash
	terraform destroy -auto-approve
	```

Destroying the bootstrap stage before the child stack can leave the regional resources running because the child configuration has its own Terraform state.
