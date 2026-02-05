; Ekip Messenger Server Installer
; Inno Setup Script
; Bu dosyayi derlemek icin Inno Setup 6.2+ gereklidir

#define MyAppName "Ekip Messenger Server"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sirketiniz"
#define MyAppURL "https://ekip.sirketiniz.com"
#define MyAppExeName "Ekip.Server.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\EkipServer
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE.txt
OutputDir=output
OutputBaseFilename=EkipServerSetup-{#MyAppVersion}
SetupIconFile=..\..\src\Ekip.Desktop\Assets\ekip.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
turkish.BeveledLabel=Ekip Messenger Sunucu Kurulum Sihirbazi
english.BeveledLabel=Ekip Messenger Server Setup Wizard

[CustomMessages]
turkish.DatabaseConfig=Veritabani Yapilandirmasi
turkish.DatabaseConfigDesc=PostgreSQL veritabani baglantisin yapilandiriniz.
turkish.RedisConfig=Redis Yapilandirmasi
turkish.RedisConfigDesc=Redis onbellek sunucusunu yapilandiriniz.
turkish.ServerConfig=Sunucu Yapilandirmasi
turkish.ServerConfigDesc=Sunucu port ve SSL ayarlarini yapilandiriniz.
turkish.ADConfig=Active Directory Yapilandirmasi
turkish.ADConfigDesc=Active Directory entegrasyonunu yapilandiriniz.
turkish.InstallComplete=Kurulum Tamamlandi
turkish.InstallCompleteDesc=Ekip Messenger Server basariyla kuruldu.
turkish.ClientInfo=Istemci Baglanti Bilgileri
turkish.DbHost=PostgreSQL Sunucu:
turkish.DbPort=Port:
turkish.DbName=Veritabani Adi:
turkish.DbUser=Kullanici Adi:
turkish.DbPassword=Sifre:
turkish.RedisHost=Redis Sunucu:
turkish.RedisPort=Port:
turkish.RedisPassword=Sifre (opsiyonel):
turkish.ServerPort=HTTP Port:
turkish.ServerPortHttps=HTTPS Port:
turkish.EnableHttps=HTTPS Etkinlestir
turkish.LdapServer=LDAP Sunucu:
turkish.BaseDN=Base DN:
turkish.EnableAD=Active Directory Entegrasyonu
turkish.TestConnection=Baglanti Test Et
turkish.ConnectionSuccess=Baglanti basarili!
turkish.ConnectionFailed=Baglanti basarisiz!
turkish.ServiceAccount=Servis Hesabi:

english.DatabaseConfig=Database Configuration
english.DatabaseConfigDesc=Configure PostgreSQL database connection.
english.RedisConfig=Redis Configuration
english.RedisConfigDesc=Configure Redis cache server.
english.ServerConfig=Server Configuration
english.ServerConfigDesc=Configure server port and SSL settings.
english.ADConfig=Active Directory Configuration
english.ADConfigDesc=Configure Active Directory integration.
english.InstallComplete=Installation Complete
english.InstallCompleteDesc=Ekip Messenger Server has been installed successfully.
english.ClientInfo=Client Connection Information
english.DbHost=PostgreSQL Server:
english.DbPort=Port:
english.DbName=Database Name:
english.DbUser=Username:
english.DbPassword=Password:
english.RedisHost=Redis Server:
english.RedisPort=Port:
english.RedisPassword=Password (optional):
english.ServerPort=HTTP Port:
english.ServerPortHttps=HTTPS Port:
english.EnableHttps=Enable HTTPS
english.LdapServer=LDAP Server:
english.BaseDN=Base DN:
english.EnableAD=Active Directory Integration
english.TestConnection=Test Connection
english.ConnectionSuccess=Connection successful!
english.ConnectionFailed=Connection failed!
english.ServiceAccount=Service Account:

[Types]
Name: "full"; Description: "Tam Kurulum (Sunucu + Admin Dashboard)"
Name: "server"; Description: "Sadece Sunucu"
Name: "custom"; Description: "Ozel Kurulum"; Flags: iscustom

[Components]
Name: "server"; Description: "Ekip Messenger Server"; Types: full server custom; Flags: fixed
Name: "admin"; Description: "Admin Dashboard"; Types: full custom
Name: "tools"; Description: "Yonetim Araclari"; Types: full custom

[Files]
; Server dosyalari
Source: "..\..\publish\server\*"; DestDir: "{app}\Server"; Flags: ignoreversion recursesubdirs; Components: server
; Admin Dashboard dosyalari
Source: "..\..\publish\admin\*"; DestDir: "{app}\Admin"; Flags: ignoreversion recursesubdirs; Components: admin
; Konfigürasyon sablonlari
Source: "config\appsettings.template.json"; DestDir: "{app}\Server"; DestName: "appsettings.json"; Flags: ignoreversion; Components: server
; Lisans ve dokumanlar
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\docs\INSTALLATION.md"; DestDir: "{app}\docs"; Flags: ignoreversion

[Dirs]
Name: "{app}\Server\logs"; Permissions: users-modify
Name: "{app}\Server\uploads"; Permissions: users-modify
Name: "{app}\Server\data"; Permissions: users-modify

[Icons]
Name: "{group}\Admin Dashboard"; Filename: "http://localhost:{code:GetHttpPort}/admin"; Components: admin
Name: "{group}\Sunucu Durumu"; Filename: "http://localhost:{code:GetHttpPort}/swagger"; Components: server
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Run]
; Windows Servisini kur
Filename: "sc.exe"; Parameters: "create EkipMessengerServer binPath= ""{app}\Server\{#MyAppExeName}"" start= auto DisplayName= ""Ekip Messenger Server"""; Flags: runhidden; StatusMsg: "Windows servisi olusturuluyor..."
; Servisi baslat
Filename: "sc.exe"; Parameters: "start EkipMessengerServer"; Flags: runhidden; StatusMsg: "Servis baslatiliyor..."
; Firewall kurali ekle
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""Ekip Messenger Server"" dir=in action=allow protocol=TCP localport={code:GetHttpPort}"; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""Ekip Messenger Server HTTPS"" dir=in action=allow protocol=TCP localport={code:GetHttpsPort}"; Flags: runhidden; Check: IsHttpsEnabled

[UninstallRun]
; Servisi durdur ve kaldir
Filename: "sc.exe"; Parameters: "stop EkipMessengerServer"; Flags: runhidden
Filename: "sc.exe"; Parameters: "delete EkipMessengerServer"; Flags: runhidden
; Firewall kurallarini kaldir
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""Ekip Messenger Server"""; Flags: runhidden
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""Ekip Messenger Server HTTPS"""; Flags: runhidden

[Code]
var
  // Veritabani sayfasi
  DbPage: TWizardPage;
  DbHostEdit, DbPortEdit, DbNameEdit, DbUserEdit, DbPasswordEdit: TEdit;

  // Redis sayfasi
  RedisPage: TWizardPage;
  RedisHostEdit, RedisPortEdit, RedisPasswordEdit: TEdit;

  // Sunucu sayfasi
  ServerPage: TWizardPage;
  ServerPortEdit, ServerPortHttpsEdit: TEdit;
  EnableHttpsCheckbox: TCheckBox;

  // AD sayfasi
  ADPage: TWizardPage;
  LdapServerEdit, BaseDNEdit, ServiceAccountEdit: TEdit;
  EnableADCheckbox: TCheckBox;

  // Sonuc sayfasi
  ResultPage: TWizardPage;
  ClientInfoMemo: TMemo;

procedure InitializeWizard;
var
  LabelFont: TFont;
begin
  // Veritabani Yapilandirma Sayfasi
  DbPage := CreateCustomPage(wpSelectComponents,
    CustomMessage('DatabaseConfig'),
    CustomMessage('DatabaseConfigDesc'));

  // PostgreSQL Host
  with TLabel.Create(DbPage) do begin
    Parent := DbPage.Surface;
    Caption := CustomMessage('DbHost');
    Left := 0;
    Top := 8;
  end;
  DbHostEdit := TEdit.Create(DbPage);
  with DbHostEdit do begin
    Parent := DbPage.Surface;
    Left := 0;
    Top := 28;
    Width := 300;
    Text := 'localhost';
  end;

  // PostgreSQL Port
  with TLabel.Create(DbPage) do begin
    Parent := DbPage.Surface;
    Caption := CustomMessage('DbPort');
    Left := 320;
    Top := 8;
  end;
  DbPortEdit := TEdit.Create(DbPage);
  with DbPortEdit do begin
    Parent := DbPage.Surface;
    Left := 320;
    Top := 28;
    Width := 80;
    Text := '5432';
  end;

  // Database Adi
  with TLabel.Create(DbPage) do begin
    Parent := DbPage.Surface;
    Caption := CustomMessage('DbName');
    Left := 0;
    Top := 60;
  end;
  DbNameEdit := TEdit.Create(DbPage);
  with DbNameEdit do begin
    Parent := DbPage.Surface;
    Left := 0;
    Top := 80;
    Width := 200;
    Text := 'ekip';
  end;

  // Kullanici Adi
  with TLabel.Create(DbPage) do begin
    Parent := DbPage.Surface;
    Caption := CustomMessage('DbUser');
    Left := 0;
    Top := 112;
  end;
  DbUserEdit := TEdit.Create(DbPage);
  with DbUserEdit do begin
    Parent := DbPage.Surface;
    Left := 0;
    Top := 132;
    Width := 200;
    Text := 'postgres';
  end;

  // Sifre
  with TLabel.Create(DbPage) do begin
    Parent := DbPage.Surface;
    Caption := CustomMessage('DbPassword');
    Left := 0;
    Top := 164;
  end;
  DbPasswordEdit := TEdit.Create(DbPage);
  with DbPasswordEdit do begin
    Parent := DbPage.Surface;
    Left := 0;
    Top := 184;
    Width := 200;
    PasswordChar := '*';
  end;

  // Redis Yapilandirma Sayfasi
  RedisPage := CreateCustomPage(DbPage.ID,
    CustomMessage('RedisConfig'),
    CustomMessage('RedisConfigDesc'));

  // Redis Host
  with TLabel.Create(RedisPage) do begin
    Parent := RedisPage.Surface;
    Caption := CustomMessage('RedisHost');
    Left := 0;
    Top := 8;
  end;
  RedisHostEdit := TEdit.Create(RedisPage);
  with RedisHostEdit do begin
    Parent := RedisPage.Surface;
    Left := 0;
    Top := 28;
    Width := 300;
    Text := 'localhost';
  end;

  // Redis Port
  with TLabel.Create(RedisPage) do begin
    Parent := RedisPage.Surface;
    Caption := CustomMessage('RedisPort');
    Left := 320;
    Top := 8;
  end;
  RedisPortEdit := TEdit.Create(RedisPage);
  with RedisPortEdit do begin
    Parent := RedisPage.Surface;
    Left := 320;
    Top := 28;
    Width := 80;
    Text := '6379';
  end;

  // Redis Sifre
  with TLabel.Create(RedisPage) do begin
    Parent := RedisPage.Surface;
    Caption := CustomMessage('RedisPassword');
    Left := 0;
    Top := 60;
  end;
  RedisPasswordEdit := TEdit.Create(RedisPage);
  with RedisPasswordEdit do begin
    Parent := RedisPage.Surface;
    Left := 0;
    Top := 80;
    Width := 200;
    PasswordChar := '*';
  end;

  // Sunucu Yapilandirma Sayfasi
  ServerPage := CreateCustomPage(RedisPage.ID,
    CustomMessage('ServerConfig'),
    CustomMessage('ServerConfigDesc'));

  // HTTP Port
  with TLabel.Create(ServerPage) do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('ServerPort');
    Left := 0;
    Top := 8;
  end;
  ServerPortEdit := TEdit.Create(ServerPage);
  with ServerPortEdit do begin
    Parent := ServerPage.Surface;
    Left := 0;
    Top := 28;
    Width := 100;
    Text := '5000';
  end;

  // HTTPS Checkbox
  EnableHttpsCheckbox := TCheckBox.Create(ServerPage);
  with EnableHttpsCheckbox do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('EnableHttps');
    Left := 0;
    Top := 64;
    Width := 200;
    Checked := True;
  end;

  // HTTPS Port
  with TLabel.Create(ServerPage) do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('ServerPortHttps');
    Left := 0;
    Top := 92;
  end;
  ServerPortHttpsEdit := TEdit.Create(ServerPage);
  with ServerPortHttpsEdit do begin
    Parent := ServerPage.Surface;
    Left := 0;
    Top := 112;
    Width := 100;
    Text := '5001';
  end;

  // Active Directory Yapilandirma Sayfasi
  ADPage := CreateCustomPage(ServerPage.ID,
    CustomMessage('ADConfig'),
    CustomMessage('ADConfigDesc'));

  // AD Checkbox
  EnableADCheckbox := TCheckBox.Create(ADPage);
  with EnableADCheckbox do begin
    Parent := ADPage.Surface;
    Caption := CustomMessage('EnableAD');
    Left := 0;
    Top := 8;
    Width := 300;
    Checked := True;
  end;

  // LDAP Server
  with TLabel.Create(ADPage) do begin
    Parent := ADPage.Surface;
    Caption := CustomMessage('LdapServer');
    Left := 0;
    Top := 40;
  end;
  LdapServerEdit := TEdit.Create(ADPage);
  with LdapServerEdit do begin
    Parent := ADPage.Surface;
    Left := 0;
    Top := 60;
    Width := 350;
    Text := 'ldap://dc.domain.local';
  end;

  // Base DN
  with TLabel.Create(ADPage) do begin
    Parent := ADPage.Surface;
    Caption := CustomMessage('BaseDN');
    Left := 0;
    Top := 92;
  end;
  BaseDNEdit := TEdit.Create(ADPage);
  with BaseDNEdit do begin
    Parent := ADPage.Surface;
    Left := 0;
    Top := 112;
    Width := 350;
    Text := 'DC=domain,DC=local';
  end;

  // Service Account
  with TLabel.Create(ADPage) do begin
    Parent := ADPage.Surface;
    Caption := CustomMessage('ServiceAccount');
    Left := 0;
    Top := 144;
  end;
  ServiceAccountEdit := TEdit.Create(ADPage);
  with ServiceAccountEdit do begin
    Parent := ADPage.Surface;
    Left := 0;
    Top := 164;
    Width := 350;
    Text := 'DOMAIN\ekip-service';
  end;

  // Sonuc Sayfasi - Istemci Baglanti Bilgileri
  ResultPage := CreateCustomPage(wpInfoAfter,
    CustomMessage('InstallComplete'),
    CustomMessage('InstallCompleteDesc'));

  with TLabel.Create(ResultPage) do begin
    Parent := ResultPage.Surface;
    Caption := CustomMessage('ClientInfo');
    Left := 0;
    Top := 8;
    Font.Style := [fsBold];
  end;

  ClientInfoMemo := TMemo.Create(ResultPage);
  with ClientInfoMemo do begin
    Parent := ResultPage.Surface;
    Left := 0;
    Top := 32;
    Width := 400;
    Height := 200;
    ReadOnly := True;
    ScrollBars := ssVertical;
    Font.Name := 'Consolas';
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  ServerUrl, HttpsUrl: String;
begin
  if CurPageID = ResultPage.ID then begin
    ServerUrl := 'http://' + GetComputerNameString + ':' + ServerPortEdit.Text;
    HttpsUrl := 'https://' + GetComputerNameString + ':' + ServerPortHttpsEdit.Text;

    ClientInfoMemo.Lines.Clear;
    ClientInfoMemo.Lines.Add('========================================');
    ClientInfoMemo.Lines.Add('  ISTEMCI BAGLANTI BILGILERI');
    ClientInfoMemo.Lines.Add('========================================');
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('Sunucu Adresi:');
    if EnableHttpsCheckbox.Checked then
      ClientInfoMemo.Lines.Add('  ' + HttpsUrl)
    else
      ClientInfoMemo.Lines.Add('  ' + ServerUrl);
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('SignalR Hub:');
    if EnableHttpsCheckbox.Checked then
      ClientInfoMemo.Lines.Add('  ' + HttpsUrl + '/hubs/message')
    else
      ClientInfoMemo.Lines.Add('  ' + ServerUrl + '/hubs/message');
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('API Endpoint:');
    if EnableHttpsCheckbox.Checked then
      ClientInfoMemo.Lines.Add('  ' + HttpsUrl + '/api')
    else
      ClientInfoMemo.Lines.Add('  ' + ServerUrl + '/api');
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('Admin Dashboard:');
    ClientInfoMemo.Lines.Add('  http://localhost:5002');
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('Swagger API Dokumantasyonu:');
    if EnableHttpsCheckbox.Checked then
      ClientInfoMemo.Lines.Add('  ' + HttpsUrl + '/swagger')
    else
      ClientInfoMemo.Lines.Add('  ' + ServerUrl + '/swagger');
    ClientInfoMemo.Lines.Add('');
    ClientInfoMemo.Lines.Add('========================================');
    ClientInfoMemo.Lines.Add('Bu bilgileri istemci kurulumunda');
    ClientInfoMemo.Lines.Add('kullanmaniz gerekmektedir.');
    ClientInfoMemo.Lines.Add('========================================');
  end;
end;

function GetHttpPort(Param: String): String;
begin
  Result := ServerPortEdit.Text;
end;

function GetHttpsPort(Param: String): String;
begin
  Result := ServerPortHttpsEdit.Text;
end;

function IsHttpsEnabled: Boolean;
begin
  Result := EnableHttpsCheckbox.Checked;
end;

function GetDbConnectionString: String;
begin
  Result := 'Host=' + DbHostEdit.Text +
            ';Port=' + DbPortEdit.Text +
            ';Database=' + DbNameEdit.Text +
            ';Username=' + DbUserEdit.Text +
            ';Password=' + DbPasswordEdit.Text;
end;

function GetRedisConnectionString: String;
begin
  if RedisPasswordEdit.Text <> '' then
    Result := RedisHostEdit.Text + ':' + RedisPortEdit.Text + ',password=' + RedisPasswordEdit.Text
  else
    Result := RedisHostEdit.Text + ':' + RedisPortEdit.Text;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: String;
  ConfigContent: TStringList;
begin
  if CurStep = ssPostInstall then begin
    // appsettings.json dosyasini olustur
    ConfigFile := ExpandConstant('{app}\Server\appsettings.json');
    ConfigContent := TStringList.Create;
    try
      ConfigContent.Add('{');
      ConfigContent.Add('  "Logging": {');
      ConfigContent.Add('    "LogLevel": {');
      ConfigContent.Add('      "Default": "Information",');
      ConfigContent.Add('      "Microsoft.AspNetCore": "Warning"');
      ConfigContent.Add('    }');
      ConfigContent.Add('  },');
      ConfigContent.Add('  "AllowedHosts": "*",');
      ConfigContent.Add('  "ConnectionStrings": {');
      ConfigContent.Add('    "PostgreSQL": "' + GetDbConnectionString + '",');
      ConfigContent.Add('    "Redis": "' + GetRedisConnectionString + '"');
      ConfigContent.Add('  },');
      ConfigContent.Add('  "Cors": {');
      ConfigContent.Add('    "Origins": ["http://localhost:5000", "https://localhost:5001"]');
      ConfigContent.Add('  },');
      ConfigContent.Add('  "FileStorage": {');
      ConfigContent.Add('    "Path": "' + ExpandConstant('{app}\Server\uploads') + '",');
      ConfigContent.Add('    "MaxFileSizeBytes": 104857600');
      ConfigContent.Add('  },');
      ConfigContent.Add('  "Kestrel": {');
      ConfigContent.Add('    "Endpoints": {');
      ConfigContent.Add('      "Http": {');
      ConfigContent.Add('        "Url": "http://0.0.0.0:' + ServerPortEdit.Text + '"');
      ConfigContent.Add('      }');
      if EnableHttpsCheckbox.Checked then begin
        ConfigContent.Add('      ,');
        ConfigContent.Add('      "Https": {');
        ConfigContent.Add('        "Url": "https://0.0.0.0:' + ServerPortHttpsEdit.Text + '"');
        ConfigContent.Add('      }');
      end;
      ConfigContent.Add('    }');
      ConfigContent.Add('  },');
      ConfigContent.Add('  "ActiveDirectory": {');
      ConfigContent.Add('    "Enabled": ' + BoolToStr(EnableADCheckbox.Checked) + ',');
      ConfigContent.Add('    "LdapServer": "' + LdapServerEdit.Text + '",');
      ConfigContent.Add('    "BaseDN": "' + BaseDNEdit.Text + '",');
      ConfigContent.Add('    "ServiceAccount": "' + ServiceAccountEdit.Text + '"');
      ConfigContent.Add('  }');
      ConfigContent.Add('}');
      ConfigContent.SaveToFile(ConfigFile);
    finally
      ConfigContent.Free;
    end;
  end;
end;

function BoolToStr(Value: Boolean): String;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;
