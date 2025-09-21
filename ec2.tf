# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id             = aws_subnet.public.id

  # Enable detailed monitoring for production
  monitoring = true

  # Root volume encryption
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-bastion-root-volume"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-host"
    Type = "Bastion"
    Role = "JumpHost"
  })
}

# Apache Web Server in Public Subnet
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.web_server.id]
  subnet_id             = aws_subnet.public.id

  # Enable detailed monitoring
  monitoring = true

  # User data for Apache installation
  user_data = local.web_server_user_data

  # Root volume encryption
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-web-server-root-volume"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-server"
    Type = "WebServer"
    Role = "Apache"
  })
}

# Optional Private EC2 Instance for Backend Services
resource "aws_instance" "private_instance" {
  count                  = var.enable_private_instance ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.private_instance[0].id]
  subnet_id             = aws_subnet.private.id

  # Enable detailed monitoring
  monitoring = true

  # User data for backend setup
  user_data = local.private_instance_user_data

  # Root volume encryption
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-private-instance-root-volume"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-instance"
    Type = "Backend"
    Role = "Application"
  })
}