# Troubleshooting Guide

## 🚨 Yaygın Sorunlar ve Çözümleri

### 1. Terraform Initialization Sorunları

**Problem**: `terraform init` başarısız oluyor
```bash
Error: Failed to query available provider packages
```

**Çözümler**:
```bash
# Terraform cache'ini temizle
rm -rf .terraform .terraform.lock.hcl

# Yeniden initialize et
terraform init

# Corporate firewall arkasındaysanız
terraform init -upgrade
```

### 2. Key Pair Bulunamıyor

**Problem**: 
```
Error: InvalidKeyPair.NotFound: The key pair 'my-key-pair' does not exist
```

**Çözümler**:
```bash
# Yeni key pair oluştur
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
chmod 400 ~/.ssh/my-key-pair.pem

# Veya mevcut key pair adını terraform.tfvars'ta kullan
key_pair_name = "existing-key-name"

# Mevcut key pair'leri listele
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName'
```

### 3. Yetersiz İzinler

**Problem**: 
```
Error: UnauthorizedOperation: You are not authorized to perform this operation
```

**Çözümler**:
```bash
# AWS credentials kontrol et
aws sts get-caller-identity

# Gerekli IAM izinleri:
# - EC2FullAccess
# - VPCFullAccess
# - IAMReadOnlyAccess

# IAM policy örneği
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### 4. Resource Limit Aşımı

**Problem**:
```
Error: VpcLimitExceeded: The maximum number of VPCs has been reached
```

**Çözümler**:
```bash
# Mevcut VPC kullanımını kontrol et
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,CidrBlock]' --output table

# Kullanılmayan VPC'leri sil
aws ec2 delete-vpc --vpc-id vpc-xxxxxxxxx

# Limit artırımı talep et
aws support create-case --service-code "vpc" --category-code "limit-increase"
```

### 5. CIDR Block Çakışmaları

**Problem**:
```
Error: InvalidVpc.Range: The CIDR '10.0.0.0/16' conflicts with another subnet
```

**Çözümler**:
```bash
# terraform.tfvars'ta farklı CIDR blokları kullan
vpc_cidr = "172.16.0.0/16"
public_subnet_cidr = "172.16.1.0/24"
private_subnet_cidr = "172.16.2.0/24"

# Mevcut CIDR'ları kontrol et
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]'
```

### 6. SSH Bağlantı Sorunları

**Problem**: Bastion host'a SSH yapamıyorum

**Debug Adımları**:
```bash
# 1. Security group kurallarını kontrol et
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx

# 2. Key pair izinlerini doğrula
ls -la ~/.ssh/my-key-pair.pem
# -r-------- (400 permissions) olmalı

# 3. Verbose output ile bağlantıyı test et
ssh -v -i ~/.ssh/my-key-pair.pem ec2-user@<bastion-ip>

# 4. Instance'ın çalışır durumda olduğunu kontrol et
aws ec2 describe-instances --instance-ids i-xxxxxxxxx --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]'

# 5. SSH port'unun açık olduğunu test et
telnet <bastion-ip> 22
# veya
nmap -p 22 <bastion-ip>
```

### 7. Web Server Erişim Sorunu

**Problem**: Web server'a HTTP ile erişemiyorum

**Debug Adımları**:
```bash
# 1. Apache'nin çalıştığını kontrol et (bastion üzerinden)
ssh -i ~/.ssh/my-key-pair.pem ec2-user@<bastion-ip>
ssh ec2-user@<web-server-private-ip>
sudo systemctl status httpd

# 2. Security group'un HTTP'ye (port 80) izin verdiğini kontrol et
aws ec2 describe-security-groups --group-ids <web-server-sg-id>

# 3. Local bağlantıyı test et
curl -I http://<web-server-public-ip>

# 4. User data loglarını kontrol et
sudo tail -f /var/log/user-data.log
sudo tail -f /var/log/cloud-init-output.log

# 5. Apache error loglarını kontrol et
sudo tail -f /var/log/httpd/error_log
```

### 8. NAT Gateway Sorunları

**Problem**: Private instance'lar internet'e erişemiyor

**Debug Adımları**:
```bash
# 1. Private subnet için route table'ı kontrol et
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=<private-subnet-id>"

# 2. NAT Gateway'in available durumda olduğunu doğrula
aws ec2 describe-nat-gateways --nat-gateway-ids <nat-gateway-id>

# 3. Private instance'tan test et (bastion üzerinden)
ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@<bastion-ip>' ec2-user@<private-ip>
curl -I http://www.google.com

# 4. DNS çözümlemesini test et
nslookup google.com
```

### 9. Terraform State Sorunları

**Problem**: State file corruption veya conflicts

**Çözümler**:
```bash
# Mevcut state'i yedekle
cp terraform.tfstate terraform.tfstate.backup

# Mevcut kaynakları import et (gerekirse)
terraform import aws_vpc.main vpc-xxxxxxxxx

# State lock'unu zorla kaldır
terraform force-unlock <lock-id>

# State'i AWS'den refresh et
terraform refresh

# State'i manuel düzenle (dikkatli kullan)
terraform state list
terraform state show aws_instance.bastion
terraform state rm aws_instance.bastion
```

### 10. Maliyet Optimizasyon Sorunları

**Problem**: Beklenmedik AWS ücretleri

**Çözümler**:
```bash
# Çalışan kaynakları kontrol et
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table

# NAT Gateway kullanımını kontrol et (saatlik ücretlendirme)
aws ec2 describe-nat-gateways --query 'NatGateways[*].[NatGatewayId,State,CreateTime]' --output table

# Elastic IP'lerin kullanımda olduğunu kontrol et
aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,InstanceId,AssociationId]' --output table

# Gerekli olmadığında kaynakları yok et
terraform destroy

# AWS Cost Explorer ile maliyetleri izle
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## 🧪 Validation Komutları

### Altyapı Validation
```bash
# Terraform konfigürasyonunu validate et
terraform validate

# Plan'ı kontrol et ve sorunları tespit et
terraform plan

# Auto-approve ile apply et (dikkatli kullan)
terraform apply -auto-approve

# Output'ları kontrol et
terraform output
terraform output -json
```

### Bağlantı Testleri
```bash
# Bastion bağlantısını test et
ssh -o ConnectTimeout=10 -i ~/.ssh/my-key-pair.pem ec2-user@$(terraform output -raw bastion_host_public_ip) exit

# Web server erişilebilirliğini test et
curl -I --max-time 10 $(terraform output -raw web_server_url)

# Private instance'a bastion üzerinden bağlantıyı test et
timeout 10 ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@$(terraform output -raw bastion_host_public_ip)' ec2-user@$(terraform output -raw private_instance_ip) exit
```

### Health Check'ler
```bash
# Web server health
curl -s $(terraform output -raw web_server_url) | grep -o '<title>.*</title>'

# Private instance health (eğer aktifse)
ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@$(terraform output -raw bastion_host_public_ip)' ec2-user@$(terraform output -raw private_instance_ip) 'curl -s localhost:8080/health | jq .'

# Instance'ların çalışır durumda olduğunu kontrol et
aws ec2 describe-instance-status --instance-ids $(terraform output -raw bastion_host_id) $(terraform output -raw web_server_id)
```

## 📊 Monitoring ve Logging

### CloudWatch Logs
```bash
# Instance system loglarını görüntüle
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2"

# Logları real-time takip et
aws logs tail /aws/ec2/instances/i-xxxxxxxxx --follow
```

### VPC Flow Logs (Opsiyonel Enhancement)
```bash
# VPC Flow Logs'u troubleshooting için aktif et
aws ec2 create-flow-logs \
    --resource-type VPC \
    --resource-ids $(terraform output -raw vpc_id) \
    --traffic-type ALL \
    --log-destination-type cloud-watch-logs \
    --log-group-name VPCFlowLogs

# Flow logs'u analiz et
aws logs filter-log-events --log-group-name VPCFlowLogs --filter-pattern "REJECT"
```

### Custom Monitoring Script
```bash
#!/bin/bash
# monitoring.sh - Altyapı health check script'i

echo "=== Infrastructure Health Check ==="

# Web server test
WEB_URL=$(terraform output -raw web_server_url)
if curl -s --max-time 10 "$WEB_URL" > /dev/null; then
    echo "✅ Web server is accessible"
else
    echo "❌ Web server is not accessible"
fi

# SSH test
BASTION_IP=$(terraform output -raw bastion_host_public_ip)
if timeout 5 bash -c "</dev/tcp/$BASTION_IP/22" 2>/dev/null; then
    echo "✅ SSH port is open on bastion"
else
    echo "❌ SSH port is not accessible on bastion"
fi

# Instance status
BASTION_ID=$(terraform output -raw bastion_host_id)
WEB_ID=$(terraform output -raw web_server_id)

echo "=== Instance Status ==="
aws ec2 describe-instances --instance-ids $BASTION_ID $WEB_ID --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table
```

## 🚨 Acil Durum Prosedürleri

### Tam Altyapı Reset
```bash
# 1. Önemli verileri yedekle
# 2. Tüm kaynakları yok et
terraform destroy -auto-approve

# 3. State'i temizle
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

# 4. Yeniden initialize et ve deploy et
terraform init
terraform plan
terraform apply
```

### Kısmi Kaynak Recovery
```bash
# Belirli kaynağı state'den kaldır (yok etmeden)
terraform state rm aws_instance.web_server

# Mevcut kaynağı import et
terraform import aws_instance.web_server i-xxxxxxxxx

# State'i refresh et
terraform refresh
```

### Emergency Access
```bash
# Eğer bastion erişilemezse, geçici olarak web server'a direct SSH
aws ec2 authorize-security-group-ingress \
    --group-id <web-server-sg-id> \
    --protocol tcp \
    --port 22 \
    --cidr <your-ip>/32

# Sorun çözüldükten sonra kuralı kaldır
aws ec2 revoke-security-group-ingress \
    --group-id <web-server-sg-id> \
    --protocol tcp \
    --port 22 \
    --cidr <your-ip>/32
```

## 📞 Destek ve Yardım

### AWS Support
```bash
# Support case oluştur
aws support create-case \
    --service-code "technical" \
    --category-code "compute" \
    --severity-code "low" \
    --subject "VPC Infrastructure Issue" \
    --communication-body "Description of the issue"
```

### Community Resources
- [AWS Forums](https://forums.aws.amazon.com/)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/terraform+aws)

### Useful Commands Cheat Sheet
```bash
# Terraform
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
terraform output
terraform state list
terraform refresh

# AWS CLI
aws sts get-caller-identity
aws ec2 describe-instances
aws ec2 describe-vpcs
aws ec2 describe-security-groups
aws logs tail <log-group> --follow

# SSH
ssh -i key.pem user@host
ssh -o ProxyCommand='ssh -W %h:%p user@bastion' user@target
ssh -o ConnectTimeout=10 user@host
```