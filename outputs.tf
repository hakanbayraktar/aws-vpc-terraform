# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Information
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = aws_subnet.private.cidr_block
}

# Bastion Host Information
output "bastion_host_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_host_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "bastion_host_id" {
  description = "Instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

# Web Server Information
output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_private_ip" {
  description = "Private IP address of the web server"
  value       = aws_instance.web_server.private_ip
}

output "web_server_id" {
  description = "Instance ID of the web server"
  value       = aws_instance.web_server.id
}

output "web_server_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

# Private Instance Information (if enabled)
output "private_instance_ip" {
  description = "Private IP address of the private instance"
  value       = var.enable_private_instance ? aws_instance.private_instance[0].private_ip : null
}

output "private_instance_id" {
  description = "Instance ID of the private instance"
  value       = var.enable_private_instance ? aws_instance.private_instance[0].id : null
}

# NAT Gateway Information
output "nat_gateway_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

# Connection Commands and Examples
output "ssh_command_bastion" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_command_web_server_via_bastion" {
  description = "SSH command to connect to web server via bastion"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem -o ProxyCommand='ssh -i ~/.ssh/${var.key_pair_name}.pem -W %h:%p ec2-user@${aws_instance.bastion.public_ip}' ec2-user@${aws_instance.web_server.private_ip}"
}

output "ssh_command_private_instance_via_bastion" {
  description = "SSH command to connect to private instance via bastion (if enabled)"
  value       = var.enable_private_instance ? "ssh -i ~/.ssh/${var.key_pair_name}.pem -o ProxyCommand='ssh -i ~/.ssh/${var.key_pair_name}.pem -W %h:%p ec2-user@${aws_instance.bastion.public_ip}' ec2-user@${aws_instance.private_instance[0].private_ip}" : "Private instance not enabled"
}

# SCP File Transfer Examples
output "scp_to_web_server_via_bastion" {
  description = "SCP command to transfer files to web server via bastion"
  value       = "scp -i ~/.ssh/${var.key_pair_name}.pem -o ProxyCommand='ssh -i ~/.ssh/${var.key_pair_name}.pem -W %h:%p ec2-user@${aws_instance.bastion.public_ip}' localfile.txt ec2-user@${aws_instance.web_server.private_ip}:~/"
}

output "scp_from_web_server_via_bastion" {
  description = "SCP command to download files from web server via bastion"
  value       = "scp -i ~/.ssh/${var.key_pair_name}.pem -o ProxyCommand='ssh -i ~/.ssh/${var.key_pair_name}.pem -W %h:%p ec2-user@${aws_instance.bastion.public_ip}' ec2-user@${aws_instance.web_server.private_ip}:~/remotefile.txt ./"
}

# SSH Config Example
output "ssh_config_example" {
  description = "SSH config file example for easier connections"
  value = <<-EOT
# Add this to ~/.ssh/config for easier connections:

Host bastion
    HostName ${aws_instance.bastion.public_ip}
    User ec2-user
    IdentityFile ~/.ssh/${var.key_pair_name}.pem
    StrictHostKeyChecking no

Host web-server
    HostName ${aws_instance.web_server.private_ip}
    User ec2-user
    IdentityFile ~/.ssh/${var.key_pair_name}.pem
    ProxyJump bastion
    StrictHostKeyChecking no

${var.enable_private_instance ? "Host private-instance\n    HostName ${aws_instance.private_instance[0].private_ip}\n    User ec2-user\n    IdentityFile ~/.ssh/${var.key_pair_name}.pem\n    ProxyJump bastion\n    StrictHostKeyChecking no" : "# Private instance not enabled"}

# Then use: ssh bastion, ssh web-server, ssh private-instance
EOT
}

# Security Group IDs
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "web_server_security_group_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web_server.id
}

output "private_instance_security_group_id" {
  description = "ID of the private instance security group"
  value       = var.enable_private_instance ? aws_security_group.private_instance[0].id : null
}

# Resource Summary
output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    vpc_id                = aws_vpc.main.id
    vpc_cidr             = aws_vpc.main.cidr_block
    public_subnet        = "${aws_subnet.public.cidr_block} (${aws_subnet.public.availability_zone})"
    private_subnet       = "${aws_subnet.private.cidr_block} (${aws_subnet.private.availability_zone})"
    bastion_ip           = aws_instance.bastion.public_ip
    web_server_ip        = aws_instance.web_server.public_ip
    web_server_url       = "http://${aws_instance.web_server.public_ip}"
    private_instance_ip  = var.enable_private_instance ? aws_instance.private_instance[0].private_ip : "Not deployed"
    nat_gateway_ip       = aws_eip.nat.public_ip
  }
}