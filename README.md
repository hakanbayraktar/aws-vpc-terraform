# AWS Production VPC Infrastructure with Terraform

This project contains Terraform code to provision a production-ready VPC infrastructure on AWS.
It delivers a secure, scalable, and cost-optimized architecture for real-world workloads.

## 🏗️ Architecture Overview

### Infrastructure Components

- **Custom VPC (10.0.0.0/16)** - Isolated network environment
- **Internet Gateway** - Provides internet access
- **Public Subnet (10.0.1.0/24, us-east-1a)** - Subnet with direct internet access
- **Private Subnet (10.0.2.0/24, us-east-1b)** - Isolated subnet without direct internet
- **NAT Gateway** - Enables outbound internet access from private subnet
- **Bastion Host** - Jump server for secure SSH access
- **Apache Web Server** - Deployed in public subnet with HTTP access
- **Optional Private EC2** - For backend services (reachable via Bastion + NAT)

### Security Features

- **Bastion Host**: SSH allowed only from your IP (restricted CIDR)
- **Web Server**: HTTP open to internet, SSH only via Bastion
- **Private Instance**: SSH only via Bastion, outbound via NAT
- **All instances share the same key pair**
- **EBS volumes encrypted by default**
- **Security Groups follow least privilege principle**

## 📋 Prerequisites

1. **AWS CLI** installed & configured
2. **Terraform** >= 1.0 installed
3. **AWS Key Pair**  created in your AWS account
4. **Required IAM permissions**:
   - EC2FullAccess
   - VPCFullAccess
   - IAMReadOnlyAccess

## 🚀 Detailed Deployment Instructions

### Verify Setup

```bash
# 1. Check AWS CLI
aws --version

# 2. Check Terraform
terraform --version

# 3. Configure AWS credentials (if not already configured)
aws configure
AWS Acces Key ID [****************3Y7H]
AWS Secret Access Key [****************l9vV] 
Default region name [us-east-1]:
Default output format [None]:


```

### Step 1: Repository Setup

```bash
git clone https://github.com/hakanbayraktar/aws-vpc-terraform
cd aws-vpc-terraform

```

### Step 2: Create AWS Key Pair

```bash

# Create a new key pair (if you don’t have one)
aws ec2 create-key-pair --key-name production-vpc-key --query 'KeyMaterial' --output text > ~/.ssh/production-vpc-key.pem

# Set permissions
chmod 400 ~/.ssh/production-vpc-key.pem

# Verify key pair exists
aws ec2 describe-key-pairs --key-names production-vpc-key
```

### Step 3: Terraform Variables Configuration

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Find your public IP
curl -s https://checkip.amazonaws.com

# Edit variables(your IP)
vi terraform.tfvars
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init
```


```bash
# Review execution plan
terraform plan
```


```bash
# Apply (with approval)
terraform apply --auto-approve

```

### Step 5: Connect to Bastion Host

```bash
ssh -i ~/.ssh/production-vpc-key.pem ec2-user@<bastion-public-ip>
```

### Step 6: Connect to Web Server via Bastion

```bash
ssh -i ~/.ssh/production-vpc-key.pem -o ProxyCommand='ssh -i ~/.ssh/production-vpc-key.pem -W %h:%p ec2-user@<bastion-ip>' ec2-user@<web-server-private-ip>
```

### Step 7: Connect to Private Instance

```bash
ssh -i ~/.ssh/production-vpc-key.pem -o ProxyCommand='ssh -i ~/.ssh/production-vpc-key.pem -W %h:%p ec2-user@<bastion-ip>' ec2-user@<private-instance-ip>
```

### Step 8: Test Web Server

```bash
curl http://<web-server-public-ip>
```


## 🧹 Resource Cleanup Commands

### ⚠️ NAT Gateway and EC2 instances incur hourly costs.
Always destroy the resources after completing the lab:

```bash

terraform destroy

```

## 📚 References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)


## 📄 License

This project is licensed under the MIT License.
