# Ekip Messenger Sunucu Kurulum Rehberi

Bu doküman, Ekip Messenger sunucusunun kurulumu, yapılandırılması ve production ortamına deploy edilmesi için gerekli adımları içerir.

## Sistem Gereksinimleri

### Donanım (Minimum)

| Kaynak | Minimum | Önerilen |
|--------|---------|----------|
| CPU | 2 vCPU | 4+ vCPU |
| RAM | 4 GB | 8+ GB |
| Disk | 50 GB SSD | 100+ GB SSD |
| Ağ | 100 Mbps | 1 Gbps |

### Yazılım Gereksinimleri

| Bileşen | Versiyon | Açıklama |
|---------|----------|----------|
| İşletim Sistemi | Windows Server 2019/2022 veya Ubuntu 22.04+ | Linux önerilen |
| .NET Runtime | 8.0+ | ASP.NET Core Runtime |
| PostgreSQL | 15+ | Ana veritabanı |
| Redis | 7+ | Cache ve session yönetimi |
| Nginx/IIS | En son sürüm | Reverse proxy (opsiyonel) |

## Kurulum Adımları

### 1. .NET 8 Runtime Kurulumu

#### Ubuntu/Debian
```bash
# Microsoft paket deposunu ekle
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# .NET Runtime kurulumu
sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-8.0
```

#### Windows Server
```powershell
# winget ile kurulum
winget install Microsoft.DotNet.AspNetCore.8

# veya manuel indirme
# https://dotnet.microsoft.com/download/dotnet/8.0
```

### 2. PostgreSQL Kurulumu

#### Ubuntu/Debian
```bash
# PostgreSQL kurulumu
sudo apt-get install -y postgresql-15

# PostgreSQL servisini başlat
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Veritabanı ve kullanıcı oluştur
sudo -u postgres psql << EOF
CREATE USER ekip_user WITH PASSWORD 'GucluSifre123!';
CREATE DATABASE ekip OWNER ekip_user;
GRANT ALL PRIVILEGES ON DATABASE ekip TO ekip_user;
EOF
```

#### Docker ile (Önerilen)
```bash
docker run -d \
  --name ekip-postgres \
  --restart unless-stopped \
  -p 5432:5432 \
  -e POSTGRES_USER=ekip_user \
  -e POSTGRES_PASSWORD=GucluSifre123! \
  -e POSTGRES_DB=ekip \
  -v ekip-postgres-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

### 3. Redis Kurulumu

#### Ubuntu/Debian
```bash
# Redis kurulumu
sudo apt-get install -y redis-server

# Redis yapılandırması
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo sed -i 's/# requirepass foobared/requirepass GucluRedisParola123!/' /etc/redis/redis.conf

# Servisi yeniden başlat
sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

#### Docker ile (Önerilen)
```bash
docker run -d \
  --name ekip-redis \
  --restart unless-stopped \
  -p 6379:6379 \
  -v ekip-redis-data:/data \
  redis:7-alpine redis-server --requirepass GucluRedisParola123!
```

### 4. Uygulama Kurulumu

#### Kaynak Koddan Derleme
```bash
# Kaynak kodu klonla
git clone https://github.com/your-org/ekip.git
cd ekip

# Release build
dotnet publish src/Ekip.Server/Ekip.Server.csproj \
  -c Release \
  -o /opt/ekip-server
```

#### Uygulama Dizini Yapısı
```
/opt/ekip-server/
├── appsettings.json          # Ana yapılandırma
├── appsettings.Production.json  # Production ayarları
├── Ekip.Server.dll           # Ana uygulama
├── uploads/                  # Dosya yükleme dizini
└── logs/                     # Log dosyaları
```

### 5. Yapılandırma

`/opt/ekip-server/appsettings.Production.json` dosyasını oluşturun:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Error"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "PostgreSQL": "Host=localhost;Port=5432;Database=ekip;Username=ekip_user;Password=GucluSifre123!",
    "Redis": "localhost:6379,password=GucluRedisParola123!"
  },
  "Cors": {
    "Origins": [
      "https://ekip.sirketiniz.com"
    ]
  },
  "FileStorage": {
    "Path": "/opt/ekip-server/uploads",
    "MaxFileSizeBytes": 104857600
  },
  "Jwt": {
    "Secret": "minimum-32-karakter-uzunlugunda-guclu-bir-secret-key-kullanin",
    "Issuer": "EkipMessenger",
    "Audience": "EkipDesktop",
    "ExpirationHours": 24
  },
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5000"
      },
      "Https": {
        "Url": "https://0.0.0.0:5001",
        "Certificate": {
          "Path": "/etc/ssl/certs/ekip.pfx",
          "Password": "SertifikaSifresi"
        }
      }
    }
  }
}
```

### 6. Dosya İzinleri
```bash
# Uygulama kullanıcısı oluştur
sudo useradd -r -s /bin/false ekip

# Dizin sahipliğini ayarla
sudo chown -R ekip:ekip /opt/ekip-server
sudo chmod -R 750 /opt/ekip-server

# Upload dizini için yazma izni
sudo chmod 770 /opt/ekip-server/uploads
```

### 7. Systemd Service Oluşturma (Linux)

`/etc/systemd/system/ekip-server.service` dosyasını oluşturun:

```ini
[Unit]
Description=Ekip Messenger Server
After=network.target postgresql.service redis.service

[Service]
Type=notify
User=ekip
Group=ekip
WorkingDirectory=/opt/ekip-server
ExecStart=/usr/bin/dotnet /opt/ekip-server/Ekip.Server.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=ekip-server
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

# Güvenlik ayarları
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ekip-server/uploads /opt/ekip-server/logs

[Install]
WantedBy=multi-user.target
```

Servisi etkinleştirin:
```bash
sudo systemctl daemon-reload
sudo systemctl enable ekip-server
sudo systemctl start ekip-server
sudo systemctl status ekip-server
```

### 8. Windows Service Kurulumu (Windows Server)

```powershell
# NSSM ile Windows Service oluşturma
# NSSM'i indir: https://nssm.cc/download

nssm install EkipServer "C:\Program Files\dotnet\dotnet.exe" `
    "C:\EkipServer\Ekip.Server.dll"
nssm set EkipServer AppDirectory "C:\EkipServer"
nssm set EkipServer AppEnvironmentExtra "ASPNETCORE_ENVIRONMENT=Production"
nssm set EkipServer DisplayName "Ekip Messenger Server"
nssm set EkipServer Start SERVICE_AUTO_START

# Servisi başlat
nssm start EkipServer
```

## Reverse Proxy Yapılandırması

### Nginx (Önerilen)

`/etc/nginx/sites-available/ekip` dosyasını oluşturun:

```nginx
upstream ekip_server {
    server 127.0.0.1:5000;
    keepalive 32;
}

server {
    listen 80;
    server_name ekip.sirketiniz.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ekip.sirketiniz.com;

    ssl_certificate /etc/ssl/certs/ekip.crt;
    ssl_certificate_key /etc/ssl/private/ekip.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # Dosya yükleme limiti
    client_max_body_size 100M;

    location / {
        proxy_pass http://ekip_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # SignalR için timeout ayarları
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # SignalR hub endpoint'i
    location /hubs/ {
        proxy_pass http://ekip_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

Etkinleştirin:
```bash
sudo ln -s /etc/nginx/sites-available/ekip /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### IIS (Windows)

1. IIS Manager'ı açın
2. "Application Request Routing" modülünü kurun
3. Site oluşturun ve Reverse Proxy yapılandırın
4. WebSocket desteğini etkinleştirin

## Active Directory Entegrasyonu

### Gereksinimler
- Sunucu, domain'e katılmış olmalı
- Servis hesabı için uygun SPN tanımlanmalı

### SPN Kayıt
```powershell
# Domain Controller'da çalıştırın
setspn -S HTTP/ekip.sirketiniz.com DOMAIN\ekip-service
setspn -S HTTP/ekip-server DOMAIN\ekip-service
```

### Keytab Oluşturma (Linux için)
```bash
# Domain Controller'da
ktpass /out ekip.keytab /princ HTTP/ekip.sirketiniz.com@DOMAIN.COM \
    /mapuser ekip-service /crypto ALL /pass * /ptype KRB5_NT_PRINCIPAL
```

## Güvenlik Önerileri

### Firewall Kuralları
```bash
# Sadece gerekli portları aç
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 80/tcp     # HTTP (redirect için)
sudo ufw deny 5000/tcp    # Direkt erişimi engelle
sudo ufw deny 5001/tcp
sudo ufw enable
```

### SSL/TLS Sertifikası
```bash
# Let's Encrypt ile ücretsiz sertifika
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d ekip.sirketiniz.com
```

### Veritabanı Güvenliği
```sql
-- Sadece gerekli IP'lerden erişime izin ver
-- pg_hba.conf dosyasını düzenleyin
host    ekip    ekip_user    10.0.0.0/24    scram-sha-256
```

## Yedekleme

### Veritabanı Yedeği
```bash
#!/bin/bash
# /opt/ekip-backup/backup.sh

BACKUP_DIR="/opt/ekip-backup"
DATE=$(date +%Y%m%d_%H%M%S)

# PostgreSQL yedeği
pg_dump -U ekip_user -h localhost ekip | gzip > "$BACKUP_DIR/ekip_db_$DATE.sql.gz"

# Upload dosyaları yedeği
tar -czf "$BACKUP_DIR/ekip_uploads_$DATE.tar.gz" /opt/ekip-server/uploads

# 7 günden eski yedekleri sil
find "$BACKUP_DIR" -name "*.gz" -mtime +7 -delete
```

Cron ile zamanlayın:
```bash
# Her gün gece 02:00'de yedek al
0 2 * * * /opt/ekip-backup/backup.sh
```

## İzleme ve Loglama

### Log Konumları
- Uygulama logları: `/opt/ekip-server/logs/`
- Systemd logları: `journalctl -u ekip-server -f`
- Nginx erişim logları: `/var/log/nginx/access.log`

### Health Check Endpoint
```bash
# Sunucu durumunu kontrol et
curl -k https://localhost:5001/health
```

## Sorun Giderme

### Yaygın Sorunlar

| Sorun | Çözüm |
|-------|-------|
| Bağlantı hatası | Firewall kurallarını kontrol edin |
| Veritabanı hatası | PostgreSQL servisini ve bağlantı bilgilerini kontrol edin |
| SignalR bağlantı kopması | Nginx timeout ayarlarını artırın |
| Dosya yükleme hatası | Upload dizini izinlerini kontrol edin |

### Log Analizi
```bash
# Son hataları görüntüle
journalctl -u ekip-server --since "1 hour ago" | grep -i error

# Gerçek zamanlı log takibi
journalctl -u ekip-server -f
```

## Production Checklist

- [ ] .NET 8 Runtime kuruldu
- [ ] PostgreSQL kuruldu ve yapılandırıldı
- [ ] Redis kuruldu ve yapılandırıldı
- [ ] SSL sertifikası yapılandırıldı
- [ ] Reverse proxy (Nginx/IIS) yapılandırıldı
- [ ] Firewall kuralları uygulandı
- [ ] Yedekleme sistemi kuruldu
- [ ] Log rotasyonu yapılandırıldı
- [ ] AD entegrasyonu test edildi
- [ ] Health monitoring kuruldu
- [ ] appsettings.Production.json güvenli şekilde yapılandırıldı

## Destek

Teknik destek için sistem yöneticinizle iletişime geçin.
