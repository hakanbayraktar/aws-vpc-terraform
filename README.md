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

# 3. AWS kaynaklarına erişebilmek için AWS credentials bilgilerini komut satırından gir
aws configure
AWS Acces Key ID [****************3Y7H]
AWS Secret Access Key [****************l9vV] 
Default region name [us-east-1]:
Default output format [None]:


```

### Adım 1: Repository Setup

```bash
# Repository'yi klonla veya dosyaları indir
git clone https://github.com/hakanbayraktar/aws-vpc-terraform
cd aws-vpc-terraform

```

### Adım 2: AWS Key Pair Hazırlığı

```bash

# Yeni key pair oluştur (eğer yoksa)
aws ec2 create-key-pair --key-name production-vpc-key --query 'KeyMaterial' --output text > ~/.ssh/production-vpc-key.pem

# İzinleri ayarla
chmod 400 ~/.ssh/production-vpc-key.pem

# Key pair'in oluştuğunu doğrula
aws ec2 describe-key-pairs --key-names production-vpc-key
```

### Adım 3: Terraform Variables Configuration

```bash
# Example dosyasını kopyala
cp terraform.tfvars.example terraform.tfvars

# Kendi IP adresini öğren (güvenlik için)
curl -s https://checkip.amazonaws.com

# terraform.tfvars dosyasını düzenle
vi terraform.tfvars
```

### Adım 4: Terraform Kodlarını Çalıştır

```bash
# Terraform'u initialize et
terraform init
```


```bash
# Execution plan oluştur
terraform plan
```


```bash
# Altyapıyı oluştur (onay iste)
terraform apply

```

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


## 🧹 Resource Cleanup Commands

### Tam Altyapı Temizliği

```bash

# Onay ile yok et
terraform destroy

```

## 📚 Ek Kaynaklar

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)


## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.
