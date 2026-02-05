# Ekip Messenger Installer Build Script
# Bu script tum bilesenleri derler ve installer'lari olusturur

param(
    [Parameter()]
    [ValidateSet("All", "Server", "Client", "Admin")]
    [string]$Target = "All",

    [Parameter()]
    [string]$Version = "1.0.0",

    [Parameter()]
    [string]$Configuration = "Release",

    [Parameter()]
    [switch]$SkipBuild,

    [Parameter()]
    [switch]$SkipInstaller
)

$ErrorActionPreference = "Stop"

# Renk fonksiyonlari
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Dizinler
$RootDir = Split-Path -Parent $PSScriptRoot
$SrcDir = Join-Path $RootDir "src"
$PublishDir = Join-Path $RootDir "publish"
$InstallerDir = $PSScriptRoot

Write-Info "========================================="
Write-Info "  Ekip Messenger Build Script"
Write-Info "  Version: $Version"
Write-Info "  Configuration: $Configuration"
Write-Info "========================================="
Write-Host ""

# Publish dizinini temizle
if (-not $SkipBuild) {
    Write-Info "Publish dizini temizleniyor..."
    if (Test-Path $PublishDir) {
        Remove-Item -Path $PublishDir -Recurse -Force
    }
    New-Item -Path $PublishDir -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $PublishDir "server") -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $PublishDir "client") -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $PublishDir "admin") -ItemType Directory | Out-Null
}

# .NET SDK kontrolu
Write-Info ".NET SDK kontrolu yapiliyor..."
try {
    $dotnetVersion = dotnet --version
    Write-Success ".NET SDK $dotnetVersion bulundu."
} catch {
    Write-Error ".NET SDK bulunamadi. Lutfen .NET 8 SDK kurunuz."
    exit 1
}

# Server Build
if ($Target -eq "All" -or $Target -eq "Server") {
    if (-not $SkipBuild) {
        Write-Info "Server derleniyor..."
        $serverProject = Join-Path $SrcDir "Ekip.Server\Ekip.Server.csproj"
        $serverOutput = Join-Path $PublishDir "server"

        dotnet publish $serverProject `
            -c $Configuration `
            -r win-x64 `
            --self-contained true `
            -p:PublishSingleFile=true `
            -p:EnableCompressionInSingleFile=true `
            -p:Version=$Version `
            -o $serverOutput

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Server derlemesi basarisiz!"
            exit 1
        }
        Write-Success "Server derlendi: $serverOutput"
    }
}

# Admin Dashboard Build
if ($Target -eq "All" -or $Target -eq "Admin") {
    if (-not $SkipBuild) {
        Write-Info "Admin Dashboard derleniyor..."
        $adminProject = Join-Path $SrcDir "Ekip.AdminDashboard\Ekip.AdminDashboard.csproj"
        $adminOutput = Join-Path $PublishDir "admin"

        dotnet publish $adminProject `
            -c $Configuration `
            -r win-x64 `
            --self-contained true `
            -p:PublishSingleFile=true `
            -p:Version=$Version `
            -o $adminOutput

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Admin Dashboard derlemesi basarisiz!"
            exit 1
        }
        Write-Success "Admin Dashboard derlendi: $adminOutput"
    }
}

# Client Build
if ($Target -eq "All" -or $Target -eq "Client") {
    if (-not $SkipBuild) {
        Write-Info "Client derleniyor..."
        $clientProject = Join-Path $SrcDir "Ekip.Desktop\Ekip.Desktop.csproj"
        $clientOutput = Join-Path $PublishDir "client"

        dotnet publish $clientProject `
            -c $Configuration `
            -r win-x64 `
            --self-contained true `
            -p:PublishSingleFile=true `
            -p:EnableCompressionInSingleFile=true `
            -p:Version=$Version `
            -o $clientOutput

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Client derlemesi basarisiz!"
            exit 1
        }
        Write-Success "Client derlendi: $clientOutput"
    }
}

# Inno Setup kontrolu
if (-not $SkipInstaller) {
    Write-Info "Inno Setup kontrolu yapiliyor..."

    $innoSetupPath = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $innoSetupPath) {
        Write-Warning "Inno Setup bulunamadi. Installer olusturulmayacak."
        Write-Warning "Inno Setup'i indirmek icin: https://jrsoftware.org/isdl.php"
    } else {
        Write-Success "Inno Setup bulundu: $innoSetupPath"

        # Server Installer
        if ($Target -eq "All" -or $Target -eq "Server") {
            Write-Info "Server installer olusturuluyor..."
            $serverIss = Join-Path $InstallerDir "server\EkipServerSetup.iss"
            $serverOutputDir = Join-Path $InstallerDir "server\output"

            if (-not (Test-Path $serverOutputDir)) {
                New-Item -Path $serverOutputDir -ItemType Directory | Out-Null
            }

            & $innoSetupPath /DMyAppVersion=$Version $serverIss

            if ($LASTEXITCODE -ne 0) {
                Write-Error "Server installer olusturulamadi!"
            } else {
                Write-Success "Server installer olusturuldu: $serverOutputDir"
            }
        }

        # Client Installer
        if ($Target -eq "All" -or $Target -eq "Client") {
            Write-Info "Client installer olusturuluyor..."
            $clientIss = Join-Path $InstallerDir "client\EkipClientSetup.iss"
            $clientOutputDir = Join-Path $InstallerDir "client\output"

            if (-not (Test-Path $clientOutputDir)) {
                New-Item -Path $clientOutputDir -ItemType Directory | Out-Null
            }

            & $innoSetupPath /DMyAppVersion=$Version $clientIss

            if ($LASTEXITCODE -ne 0) {
                Write-Error "Client installer olusturulamadi!"
            } else {
                Write-Success "Client installer olusturuldu: $clientOutputDir"
            }
        }
    }
}

Write-Host ""
Write-Info "========================================="
Write-Success "  Build islemi tamamlandi!"
Write-Info "========================================="
Write-Host ""

# Cikti bilgileri
if (-not $SkipBuild) {
    Write-Info "Derleme ciktilari:"
    Write-Host "  Server:  $PublishDir\server"
    Write-Host "  Admin:   $PublishDir\admin"
    Write-Host "  Client:  $PublishDir\client"
}

if (-not $SkipInstaller -and $innoSetupPath) {
    Write-Host ""
    Write-Info "Installer dosyalari:"
    Write-Host "  Server:  $InstallerDir\server\output"
    Write-Host "  Client:  $InstallerDir\client\output"
}
