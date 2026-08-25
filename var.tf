variable "bootstrap_region" {
  description = "Region where the Terraform runner and handoff bucket are created"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the Terraform runner"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Terraform runner"
  type        = string
  default     = "t3.micro"
}
