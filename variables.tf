# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in valid format (e.g., us-east-1)."
  }
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "production-vpc"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name can only contain alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet (us-east-1a)"
  type        = string
  default     = "10.0.1.0/24"
  
  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet (us-east-1b)"
  type        = string
  default     = "10.0.2.0/24"
  
  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private subnet CIDR must be a valid IPv4 CIDR block."
  }
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  
  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name cannot be empty."
  }
}

# Security Configuration
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion host"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Allowed SSH CIDR must be a valid IPv4 CIDR block."
  }
}

# Optional Features
variable "enable_private_instance" {
  description = "Enable optional private EC2 instance for backend services"
  type        = bool
  default     = true
}

# Common tags for all resources
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Production VPC"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}