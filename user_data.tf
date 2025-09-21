# User Data Script for Apache Web Server
locals {
  web_server_user_data = base64encode(<<-EOF
#!/bin/bash
# Log all output for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting web server setup..."

# Update system
yum update -y

# Install Apache and other tools
yum install -y httpd htop curl wget

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a production-ready HTML page
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Production Apache Web Server</title>
    <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 20px; text-align: center; border-radius: 10px; margin-bottom: 30px; }
            .header h1 { font-size: 2.5em; margin-bottom: 10px; }
            .header p { font-size: 1.2em; opacity: 0.9; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
            .card { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border-left: 4px solid #667eea; }
            .card h3 { color: #667eea; margin-bottom: 15px; font-size: 1.3em; }
            .card p { margin-bottom: 10px; }
            .status { background: #e8f5e8; border-left-color: #28a745; }
            .info { background: #e3f2fd; border-left-color: #2196f3; }
            .architecture { background: #fff3e0; border-left-color: #ff9800; }
            .footer { text-align: center; padding: 20px; color: #666; border-top: 1px solid #eee; margin-top: 30px; }
            .badge { display: inline-block; background: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-size: 0.8em; margin-right: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Production Apache Web Server</h1>
            <p>AWS'de Terraform ile başarıyla deploy edildi</p>
        </div>
        
        <div class="grid">
            <div class="card status">
                <h3>🟢 Server Durumu</h3>
                <p><strong>Status:</strong> <span class="badge">ONLINE</span></p>
                <p><strong>Instance ID:</strong> <span id="instance-id">Yükleniyor...</span></p>
                <p><strong>Availability Zone:</strong> <span id="az">Yükleniyor...</span></p>
                <p><strong>Private IP:</strong> <span id="private-ip">Yükleniyor...</span></p>
                <p><strong>Public IP:</strong> <span id="public-ip">Yükleniyor...</span></p>
            </div>
            
            <div class="card info">
                <h3>📊 Altyapı Detayları</h3>
                <p><strong>VPC CIDR:</strong> 10.0.0.0/16</p>
                <p><strong>Public Subnet:</strong> 10.0.1.0/24 (us-east-1a)</p>
                <p><strong>Private Subnet:</strong> 10.0.2.0/24 (us-east-1b)</p>
                <p><strong>Environment:</strong> Production</p>
            </div>
            
            <div class="card architecture">
                <h3>🏗️ Mimari Bileşenler</h3>
                <p>✅ Custom VPC with Internet Gateway</p>
                <p>✅ Public & Private Subnets</p>
                <p>✅ Bastion Host for secure access</p>
                <p>✅ Apache Web Server</p>
                <p>✅ NAT Gateway for outbound traffic</p>
                <p>✅ Security Groups & NACLs</p>
            </div>
        </div>
        
        <div class="footer">
            <p>Terraform ile ❤️ ile deploy edildi | AWS Infrastructure | $(date)</p>
        </div>
    </div>
    
</body>
</html>
HTML

# --- Server-side: IMDSv2 token + metadata al, HTML'e yaz ---
TOKEN=$(curl -sS -m 2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
IMDS_H=""
if [ -n "$TOKEN" ]; then IMDS_H="-H X-aws-ec2-metadata-token: $TOKEN"; fi

INSTANCE_ID=$(curl -sS -m 2 $IMDS_H http://169.254.169.254/latest/meta-data/instance-id || echo "N/A")
AZ=$(curl -sS -m 2 $IMDS_H http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "N/A")
PRIVATE_IP=$(curl -sS -m 2 $IMDS_H http://169.254.169.254/latest/meta-data/local-ipv4 || echo "N/A")
PUBLIC_IP=$(curl -sS -m 2 $IMDS_H http://169.254.169.254/latest/meta-data/public-ipv4 || echo "N/A")

sed -i 's#<span id="instance-id">[^<]*</span>#<span id="instance-id">'"$INSTANCE_ID"'</span>#g' /var/www/html/index.html
sed -i 's#<span id="az">[^<]*</span>#<span id="az">'"$AZ"'</span>#g' /var/www/html/index.html
sed -i 's#<span id="private-ip">[^<]*</span>#<span id="private-ip">'"$PRIVATE_IP"'</span>#g' /var/www/html/index.html
sed -i 's#<span id="public-ip">[^<]*</span>#<span id="public-ip">'"$PUBLIC_IP"'</span>#g' /var/www/html/index.html

# Set proper permissions
chown apache:apache /var/www/html/index.html
chmod 644 /var/www/html/index.html

# Configure Apache for production
echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf
echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf

# Restart Apache
systemctl restart httpd

# Verify Apache is running
systemctl status httpd

echo "Web server setup completed successfully" >> /var/log/user-data.log
EOF
  )

  # User Data Script for Private Instance (orijinal)
  private_instance_user_data = base64encode(<<-EOF
#!/bin/bash
# Log all output for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting private instance setup..."

# Update system
yum update -y

# Install useful tools for backend services
yum install -y htop curl wget git docker

# Start and enable Docker (for containerized applications)
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Node.js (example backend runtime)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create a simple backend service directory
mkdir -p /opt/backend
chown ec2-user:ec2-user /opt/backend

# Create a simple Node.js health check service
cat <<JS > /opt/backend/server.js
const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      hostname: os.hostname(),
      uptime: process.uptime()
    }));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(8080, () => {
  console.log('Backend service running on port 8080');
});
JS

# Create systemd service for the backend
cat <<SERVICE > /etc/systemd/system/backend.service
[Unit]
Description=Backend Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

# Set permissions and start the service
chown ec2-user:ec2-user /opt/backend/server.js
systemctl daemon-reload
systemctl enable backend
systemctl start backend

echo "Private instance setup completed successfully" >> /var/log/user-data.log
EOF
  )
}
