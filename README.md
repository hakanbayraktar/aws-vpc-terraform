# AWS Production VPC Infrastructure with Terraform

Bu proje, AWS'de production-ready bir VPC altyapısı kurmak için Terraform kodlarını içerir. Güvenli, ölçeklenebilir ve maliyet-optimized bir mimari sunar.

## 🏗️ Mimari Genel Bakış

### Altyapı Bileşenleri

- **Custom VPC (10.0.0.0/16)** - İzole edilmiş ağ ortamı
- **Internet Gateway** - İnternet bağlantısı
- **Public Subnet (10.0.1.0/24, us-east-1a)** - İnternet erişimi olan subnet
- **Private Subnet (10.0.2.0/24, us-east-1b)** - İzole edilmiş subnet
- **NAT Gateway** - Private subnet'ten outbound internet erişimi
- **Bastion Host** - Güvenli SSH erişimi için jump host
- **Apache Web Server** - Public subnet'te web sunucusu
- **Optional Private EC2** - Backend servisleri için

### Güvenlik Özellikleri

- **Bastion Host**: SSH sadece belirtilen CIDR'dan
- **Web Server**: HTTP internet'ten, SSH sadece bastion'dan
- **Private Instance**: SSH sadece bastion'dan, outbound NAT üzerinden
- **Tüm instance'lar aynı key pair kullanır**
- **EBS volume'lar şifrelenmiş**
- **Security group'lar least privilege prensibi**

## 📋 Ön Gereksinimler

1. **AWS CLI** kurulu ve yapılandırılmış
2. **Terraform** >= 1.0 kurulu
3. **AWS hesabında Key Pair** oluşturulmuş
4. **Gerekli IAM izinleri**:
   - EC2FullAccess
   - VPCFullAccess
   - IAMReadOnlyAccess

## 🚀 Detailed Deployment Instructions

### Ön Hazırlık Kontrolleri

```bash
# 1. AWS CLI kurulu mu kontrol et
aws --version

# 2. Terraform kurulu mu kontrol et
terraform --version

# 3. AWS credentials yapılandırılmış mı kontrol et
aws sts get-caller-identity

# 4. Gerekli izinlerin olduğunu kontrol et
aws iam get-user
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query User.UserName --output text)
```

### Adım 1: Repository Setup

```bash
# Repository'yi klonla veya dosyaları indir
git clone <repository-url>
cd aws-vpc-terraform

# Veya manuel olarak dosyaları oluştur
mkdir aws-vpc-terraform
cd aws-vpc-terraform
# Tüm .tf dosyalarını bu klasöre kopyala
```

### Adım 2: AWS Key Pair Hazırlığı

```bash
# Mevcut key pair'leri listele
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName'

# Yeni key pair oluştur (eğer yoksa)
aws ec2 create-key-pair --key-name production-vpc-key --query 'KeyMaterial' --output text > ~/.ssh/production-vpc-key.pem

# İzinleri ayarla
chmod 400 ~/.ssh/production-vpc-key.pem

# Key pair'in oluştuğunu doğrula
aws ec2 describe-key-pairs --key-names production-vpc-key
```

### Adım 3: Network Planning

```bash
# Mevcut VPC'leri kontrol et (CIDR çakışması olmasın)
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,State]' --output table

# Kullanılabilir AZ'leri kontrol et
aws ec2 describe-availability-zones --query 'AvailabilityZones[*].[ZoneName,State]' --output table
```

### Adım 4: Terraform Variables Configuration

```bash
# Example dosyasını kopyala
cp terraform.tfvars.example terraform.tfvars

# Kendi IP adresini öğren (güvenlik için)
curl -s https://checkip.amazonaws.com

# terraform.tfvars dosyasını düzenle
nano terraform.tfvars
```

**terraform.tfvars örnek konfigürasyon**:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "my-production-vpc"
environment  = "prod"

# Network Configuration
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidr    = "10.0.1.0/24"    # us-east-1a
private_subnet_cidr   = "10.0.2.0/24"    # us-east-1b

# EC2 Configuration
instance_type = "t3.micro"
key_pair_name = "production-vpc-key"  # Yukarıda oluşturduğunuz key

# Security Configuration - KENDİ IP ADRESİNİZİ YAZIN!
allowed_ssh_cidr = "203.0.113.0/32"  # curl -s https://checkip.amazonaws.com

# Optional Features
enable_private_instance = true

# Resource Tags
common_tags = {
  Project     = "Production VPC Infrastructure"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
}
```

### Adım 5: Terraform Initialization

```bash
# Terraform'u initialize et
terraform init

# Provider'ların indirildiğini kontrol et
ls -la .terraform/providers/

# Konfigürasyonu validate et
terraform validate
```

### Adım 6: Infrastructure Planning

```bash
# Execution plan oluştur
terraform plan

# Plan'ı dosyaya kaydet (opsiyonel)
terraform plan -out=tfplan

# Plan'ı detaylı incele
terraform show tfplan
```

### Adım 7: Infrastructure Deployment

```bash
# Altyapıyı oluştur (onay iste)
terraform apply

# Veya plan dosyasından apply et
terraform apply tfplan

# Otomatik onay ile (production'da dikkatli kullan)
terraform apply -auto-approve
```

### Adım 8: Deployment Verification

```bash
# Output'ları kontrol et
terraform output

# JSON formatında output'ları al
terraform output -json

# Belirli output'u al
terraform output web_server_url
terraform output ssh_command_bastion

# AWS Console'dan kaynakları kontrol et
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Adım 9: Connectivity Testing

```bash
# Web server'ı test et
curl -I $(terraform output -raw web_server_url)

# SSH bağlantısını test et
ssh -o ConnectTimeout=10 -i ~/.ssh/production-vpc-key.pem ec2-user@$(terraform output -raw bastion_host_public_ip) exit

# Private instance'a bastion üzerinden bağlan
ssh -i ~/.ssh/production-vpc-key.pem -o ProxyCommand='ssh -i ~/.ssh/production-vpc-key.pem -W %h:%p ec2-user@$(terraform output -raw bastion_host_public_ip)' ec2-user@$(terraform output -raw private_instance_ip)
```

### Adım 10: Post-Deployment Configuration

```bash
# Security group'ları fine-tune et
aws ec2 describe-security-groups --group-ids $(terraform output -raw bastion_security_group_id)

# CloudWatch monitoring aktif et
aws logs create-log-group --log-group-name /aws/ec2/vpc-infrastructure

# Backup stratejisi kur
aws ec2 create-snapshot --volume-id $(aws ec2 describe-instances --instance-ids $(terraform output -raw web_server_id) --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)
```

### Troubleshooting During Deployment

```bash
# Eğer deployment başarısız olursa:

# 1. Hata mesajını analiz et
terraform apply 2>&1 | tee deployment.log

# 2. State'i kontrol et
terraform state list

# 3. Belirli kaynağı yeniden oluştur
terraform taint aws_instance.web_server
terraform apply

# 4. Kısmi deployment'ı temizle
terraform destroy -target=aws_instance.web_server
```

## 🔧 Kullanım

### Bastion Host'a Bağlanma

```bash
ssh -i ~/.ssh/my-key-pair.pem ec2-user@<bastion-public-ip>
```

### Web Server'a Bastion Üzerinden Bağlanma

```bash
ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@<bastion-ip>' ec2-user@<web-server-private-ip>
```

### Private Instance'a Bağlanma

```bash
ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@<bastion-ip>' ec2-user@<private-instance-ip>
```

### Web Sitesine Erişim

```bash
curl http://<web-server-public-ip>
```

## 📊 Outputs

Deployment sonrası önemli bilgiler:

```bash
terraform output
```

Önemli output'lar:

- `web_server_url`: Web sunucusu URL'i
- `ssh_command_bastion`: Bastion'a bağlanma komutu
- `infrastructure_summary`: Altyapı özeti

## 🧪 Validation ve Test

### Terraform Validation

```bash
terraform validate
```

### Connectivity Tests

```bash
# Web server test
curl -I $(terraform output -raw web_server_url)

# SSH connectivity test
ssh -o ConnectTimeout=5 -i ~/.ssh/my-key-pair.pem ec2-user@$(terraform output -raw bastion_host_public_ip) exit
```

### Health Checks

```bash
# Web server health
curl -s $(terraform output -raw web_server_url) | grep -o '<title>.*</title>'

# Private instance health (if enabled)
ssh -i ~/.ssh/my-key-pair.pem -o ProxyCommand='ssh -i ~/.ssh/my-key-pair.pem -W %h:%p ec2-user@$(terraform output -raw bastion_host_public_ip)' ec2-user@$(terraform output -raw private_instance_ip) 'curl -s localhost:8080/health'
```

## 🔒 Güvenlik Best Practices

1. **SSH Access**: `allowed_ssh_cidr`'ı kendi IP'nizle sınırlayın
2. **Key Management**: Private key'leri güvenli saklayın
3. **Regular Updates**: Instance'ları düzenli güncelleyin
4. **Monitoring**: CloudWatch ile monitoring aktif edin
5. **Backup**: Önemli data'yı yedekleyin

## 💰 Cost Optimization Suggestions

### Maliyet Bileşenleri (Aylık Tahmini)

- **EC2 Instances (3x t3.micro)**: $0-10 (Free Tier eligible)
- **NAT Gateway**: $45 (saatlik $0.045 + data transfer)
- **EBS Volumes (3x 20GB gp3)**: $6 ($0.08/GB/ay)
- **Elastic IP**: $0 (kullanımdayken ücretsiz)
- **Data Transfer**: Değişken (ilk 1GB ücretsiz)

**Toplam Tahmini Maliyet**: ~$51/ay

### Maliyet Optimizasyon Stratejileri

#### 1. Development/Test Ortamları İçin

```bash
# Private instance'ı devre dışı bırak
enable_private_instance = false

# Daha küçük instance type kullan
instance_type = "t2.micro"  # Free Tier

# Test sonrası kaynakları temizle
terraform destroy
```

#### 2. NAT Gateway Alternatifleri

```bash
# NAT Instance kullan (daha ucuz ama yönetim gerektirir)
# Veya private subnet'i public yap (güvenlik riski)

# Scheduled start/stop için Lambda function
aws events put-rule --name "stop-instances" --schedule-expression "cron(0 18 * * ? *)"
```

#### 3. Instance Scheduling

```bash
# Instance'ları gece durdur, sabah başlat
aws ec2 stop-instances --instance-ids i-xxxxxxxxx
aws ec2 start-instances --instance-ids i-xxxxxxxxx

# Auto Scaling ile demand-based scaling
# CloudWatch alarms ile cost monitoring
```

#### 4. Storage Optimization

```bash
# EBS volume'ları optimize et
aws ec2 modify-volume --volume-id vol-xxxxxxxxx --volume-type gp3 --size 10

# Snapshot'ları düzenli temizle
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[?StartTime<=`2024-01-01`]'
```

#### 5. Monitoring ve Alerting

```bash
# AWS Cost Explorer ile maliyet takibi
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

# Budget alarm oluştur
aws budgets create-budget --account-id 123456789012 --budget '{
  "BudgetName": "VPC-Infrastructure-Budget",
  "BudgetLimit": {"Amount": "100", "Unit": "USD"},
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

#### 6. Reserved Instances (Production)

```bash
# 1-3 yıllık Reserved Instance ile %75'e kadar tasarruf
# Spot Instances ile %90'a kadar tasarruf (uygun workload'lar için)

# RI satın alma
aws ec2 purchase-reserved-instances-offering --reserved-instances-offering-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx --instance-count 1
```

### Maliyet İzleme Komutları

```bash
# Güncel maliyet raporu
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "1 month ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Resource tagging ile maliyet takibi
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project

# Unutulan kaynakları bul
aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name==`stopped`].[InstanceId,LaunchTime]'
aws ec2 describe-volumes --query 'Volumes[?State==`available`].[VolumeId,CreateTime]'
```

## 🛠️ Troubleshooting

### Common Issues

1. **Key Pair Not Found**

```bash
aws ec2 describe-key-pairs --key-names my-key-pair
```

2. **Permission Denied**

```bash
aws sts get-caller-identity
```

3. **CIDR Conflicts**

```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]'
```

4. **SSH Connection Issues**

```bash
# Test SSH port
telnet <bastion-ip> 22

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Logs ve Debugging

```bash
# Instance logs
ssh -i ~/.ssh/my-key-pair.pem ec2-user@<bastion-ip>
sudo tail -f /var/log/user-data.log
sudo tail -f /var/log/cloud-init-output.log
```

## 🔄 Remote State (Production)

Production ortamında remote state kullanın:

1. **S3 Bucket oluşturun**:

```bash
aws s3 mb s3://my-terraform-state-bucket
```

2. **DynamoDB table oluşturun**:

```bash
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

3. **main.tf'de backend'i aktif edin**:

```hcl
backend "s3" {
  bucket         = "my-terraform-state-bucket"
  key            = "vpc/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

## 🧹 Resource Cleanup Commands

### Tam Altyapı Temizliği

```bash
# Tüm kaynakları listele
terraform state list

# Planı kontrol et
terraform plan -destroy

# Onay ile yok et
terraform destroy

# Otomatik onay ile yok et (dikkatli kullan)
terraform destroy -auto-approve

# Belirli kaynakları hedefle
terraform destroy -target=aws_instance.private_instance
```

### Kısmi Temizlik

```bash
# Sadece private instance'ı kaldır
terraform apply -var="enable_private_instance=false"

# Belirli kaynağı state'den kaldır (AWS'de bırak)
terraform state rm aws_instance.private_instance

# Kullanılmayan Elastic IP'leri temizle
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null]'
aws ec2 release-address --allocation-id eipalloc-xxxxxxxxx
```

### State Temizliği

```bash
# Local state dosyalarını temizle
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

# Remote state'i temizle (dikkatli!)
aws s3 rm s3://your-terraform-state-bucket/vpc/terraform.tfstate
```

## 📚 Ek Kaynaklar

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun
3. Commit edin
4. Push edin
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
