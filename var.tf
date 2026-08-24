variable "aws_region_virginia" {
  description = "AWS region for Virginia resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_region_ohio" {
  description = "AWS region for Ohio resources"
  type        = string
  default     = "us-east-2"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "ami_id_ohio" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for all application servers"
  type        = string
  default     = "t3.micro"
}