# Ekip Messenger

Kurumsal iç iletişim için tasarlanmış, Windows ekosistemiyle tam entegre, yüksek güvenlikli ve modern bir anlık mesajlaşma uygulaması.

## Genel Bakış

Ekip Messenger, kurumsal kimlik yönetimi (Active Directory) ile uyumlu, denetlenebilir (Surveillance/DLP) ve kullanıcı dostu bir haberleşme altyapısı sağlar.

### Temel Özellikler

- **Windows AD Entegrasyonu**: LDAP/Kerberos ile mevcut oturumlarla otomatik giriş (SSO)
- **Gerçek Zamanlı Mesajlaşma**: SignalR tabanlı düşük gecikmeli mesaj iletimi
- **Birebir ve Grup Sohbeti**: Özel veya çoklu katılımcılı grup sohbetleri
- **Dosya Paylaşımı**: Sürükle-bırak ile her türlü dosya transferi
- **Ekran Görüntüsü Aracı**: Dahili ekran yakalama ve çizim araçları
- **Durum Yönetimi**: Uygun, Meşgul, Dışarıda, Çevrimdışı durumları
- **Surveillance Entegrasyonu**: DLP ve arşivleme servisleri için API/Webhook desteği
- **Karanlık/Aydınlık Mod**: Windows temasına uyumlu Fluent Design

## Mimari

```
┌─────────────────────────────────────────────────────────────────┐
│                      Ekip.Desktop (WPF)                         │
│                     Windows Desktop Client                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ SignalR / HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Ekip.Server                                │
│                   ASP.NET Core 8 API                            │
│         ┌──────────────────┬──────────────────┐                 │
│         │    SignalR Hub   │    REST API      │                 │
│         └──────────────────┴──────────────────┘                 │
│                              │                                   │
│         ┌──────────────────┬──────────────────┐                 │
│         │    PostgreSQL    │      Redis       │                 │
│         │   (Ana Veritabanı)│    (Cache)      │                 │
│         └──────────────────┴──────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Desktop Client | WPF, .NET 8, CommunityToolkit.Mvvm |
| Backend API | ASP.NET Core 8, SignalR |
| Veritabanı | PostgreSQL 15+ |
| Cache | Redis 7+ |
| Authentication | Windows Negotiate (Kerberos/NTLM) |

## Proje Yapısı

```
ekip/
├── src/
│   ├── Ekip.Desktop/          # WPF Windows masaüstü uygulaması
│   │   ├── Views/             # XAML görünümleri
│   │   ├── ViewModels/        # MVVM view modelleri
│   │   ├── Services/          # API ve SignalR istemcileri
│   │   ├── Themes/            # Fluent Design stilleri
│   │   └── Converters/        # XAML dönüştürücüleri
│   │
│   ├── Ekip.Server/           # ASP.NET Core backend
│   │   ├── Controllers/       # REST API controller'ları
│   │   ├── Hubs/              # SignalR hub'ları
│   │   ├── Services/          # İş mantığı servisleri
│   │   └── Data/              # Entity Framework context ve entity'ler
│   │
│   ├── Ekip.AdminDashboard/   # Blazor Server admin paneli
│   │   ├── Pages/             # Razor sayfaları
│   │   ├── Services/          # Dashboard servisleri
│   │   └── Shared/            # Layout ve bileşenler
│   │
│   └── Ekip.Shared/           # Ortak modeller ve DTO'lar
│       ├── DTOs/              # Veri transfer objeleri
│       ├── Enums/             # Enum tanımları
│       └── Interfaces/        # Ortak interface'ler
│
├── installers/
│   ├── server/                # Sunucu installer (Inno Setup)
│   ├── client/                # İstemci installer (Inno Setup)
│   └── build.ps1              # Build ve paketleme scripti
│
├── docs/
│   ├── PRD.md                 # Ürün Gereksinim Dokümanı
│   └── INSTALLATION.md        # Sunucu kurulum rehberi
│
└── Ekip.sln                   # Visual Studio solution dosyası
```

## Hızlı Başlangıç

### Gereksinimler

- .NET 8 SDK
- PostgreSQL 15+
- Redis 7+
- Windows 10/11 (Desktop client için)
- Visual Studio 2022 veya VS Code

### 1. Repository'yi Klonlayın

```bash
git clone https://github.com/your-org/ekip.git
cd ekip
```

### 2. Veritabanlarını Başlatın

```bash
# Docker ile (önerilen)
docker run -d --name ekip-postgres -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=ekip \
  postgres:15

docker run -d --name ekip-redis -p 6379:6379 redis:7-alpine
```

### 3. Sunucuyu Çalıştırın

```bash
cd src/Ekip.Server
dotnet run
```

Sunucu varsayılan olarak `https://localhost:5001` adresinde çalışır.

### 4. Desktop İstemcisini Çalıştırın

```bash
cd src/Ekip.Desktop
dotnet run
```

## API Dokümantasyonu

Sunucu çalıştırıldığında Swagger UI şu adreste erişilebilir:
- https://localhost:5001/swagger

## Konfigürasyon

Sunucu ayarları `src/Ekip.Server/appsettings.json` dosyasından yapılandırılır:

```json
{
  "ConnectionStrings": {
    "PostgreSQL": "Host=localhost;Port=5432;Database=ekip;Username=postgres;Password=postgres",
    "Redis": "localhost:6379"
  },
  "FileStorage": {
    "Path": "./uploads",
    "MaxFileSizeBytes": 104857600
  },
  "Jwt": {
    "Secret": "your-super-secret-key-here",
    "ExpirationHours": 24
  }
}
```

## Kullanıcı Rolleri

| Rol | Yetkiler |
|-----|----------|
| Kullanıcı | Mesaj gönderme, dosya paylaşma, durum yönetimi |
| Moderatör | Grup sohbetlerini yönetme, kullanıcı ekleme/çıkarma |
| Sistem Yöneticisi | AD entegrasyonu, gözetim araçları, log denetimi |

## Kurulum

### Installer ile Kurulum (Önerilen)

#### Sunucu Kurulumu
1. `EkipServerSetup-x.x.x.exe` dosyasını çalıştırın
2. Kurulum sihirbazı sizi yönlendirecektir:
   - PostgreSQL bağlantı bilgilerini girin
   - Redis bağlantı bilgilerini girin
   - Sunucu port ayarlarını yapın
   - Active Directory ayarlarını yapılandırın
3. Kurulum tamamlandığında istemci bağlantı bilgileri gösterilecektir

#### İstemci Kurulumu
1. `EkipSetup-x.x.x.exe` dosyasını çalıştırın
2. Sunucu bağlantı bilgilerini girin (sunucu kurulumunda verilen bilgiler)
3. Kullanıcı tercihlerini yapılandırın
4. Kurulum tamamlandığında uygulama otomatik başlayacaktır

### Installer Oluşturma

Installer dosyalarını oluşturmak için:

```powershell
# Tüm bileşenleri derle ve installer'ları oluştur
.\installers\build.ps1 -Target All -Version "1.0.0"

# Sadece sunucu installer'ını oluştur
.\installers\build.ps1 -Target Server -Version "1.0.0"

# Sadece istemci installer'ını oluştur
.\installers\build.ps1 -Target Client -Version "1.0.0"
```

**Gereksinimler:**
- Windows 10/11 veya Windows Server 2019+
- .NET 8 SDK
- [Inno Setup 6.2+](https://jrsoftware.org/isdl.php)

## Admin Dashboard

Admin Dashboard, sunucu ile birlikte kurulur ve şu özellikleri sunar:
- Kullanıcı yönetimi
- Grup yönetimi
- Mesaj istatistikleri
- Sistem durumu izleme
- Gözetim (Surveillance) ayarları
- Sistem yapılandırması

Varsayılan olarak `http://localhost:5002` adresinde erişilebilir.

## Lisans

Bu proje özel/kurumsal kullanım içindir.

## Destek

Teknik destek için sistem yöneticinizle iletişime geçin.
