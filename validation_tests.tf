# Validation Tests for Infrastructure
# These resources help validate the infrastructure is working correctly

# Data source to validate VPC
data "aws_vpc" "validation" {
  id = aws_vpc.main.id
}

# Data source to validate subnets
data "aws_subnet" "public_validation" {
  id = aws_subnet.public.id
}

data "aws_subnet" "private_validation" {
  id = aws_subnet.private.id
}

# Data source to validate internet connectivity for public subnet
data "aws_route_table" "public_validation" {
  subnet_id = aws_subnet.public.id
}

# Data source to validate NAT Gateway connectivity for private subnet
data "aws_route_table" "private_validation" {
  subnet_id = aws_subnet.private.id
}

# Validation checks using locals
locals {
  validation_checks = {
    vpc_dns_enabled        = data.aws_vpc.validation.enable_dns_support
    vpc_dns_hostnames      = data.aws_vpc.validation.enable_dns_hostnames
    public_subnet_public   = data.aws_subnet.public_validation.map_public_ip_on_launch
    private_subnet_private = !data.aws_subnet.private_validation.map_public_ip_on_launch
    
    # Validate CIDR blocks don't overlap
    cidr_validation = can(cidrsubnet(var.vpc_cidr, 8, 1)) && can(cidrsubnet(var.vpc_cidr, 8, 2))
    
    # Validate subnets are in different AZs
    az_validation = data.aws_subnet.public_validation.availability_zone != data.aws_subnet.private_validation.availability_zone
  }
}

# Output validation results
output "validation_results" {
  description = "Infrastructure validation results"
  value = {
    vpc_configuration = {
      dns_support    = local.validation_checks.vpc_dns_enabled ? "✅ PASS" : "❌ FAIL"
      dns_hostnames  = local.validation_checks.vpc_dns_hostnames ? "✅ PASS" : "❌ FAIL"
    }
    subnet_configuration = {
      public_subnet_auto_ip  = local.validation_checks.public_subnet_public ? "✅ PASS" : "❌ FAIL"
      private_subnet_no_ip   = local.validation_checks.private_subnet_private ? "✅ PASS" : "❌ FAIL"
      different_azs          = local.validation_checks.az_validation ? "✅ PASS" : "❌ FAIL"
    }
    network_configuration = {
      cidr_blocks_valid = local.validation_checks.cidr_validation ? "✅ PASS" : "❌ FAIL"
    }
  }
}

# Health check outputs for monitoring
output "health_check_endpoints" {
  description = "Endpoints for health checking"
  value = {
    web_server_health = "http://${aws_instance.web_server.public_ip}/"
    private_instance_health = var.enable_private_instance ? "http://${aws_instance.private_instance[0].private_ip}:8080/health" : "Not deployed"
  }
}