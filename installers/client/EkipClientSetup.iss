; Ekip Messenger Client Installer
; Inno Setup Script
; Bu dosyayi derlemek icin Inno Setup 6.2+ gereklidir

#define MyAppName "Ekip Messenger"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sirketiniz"
#define MyAppURL "https://ekip.sirketiniz.com"
#define MyAppExeName "Ekip.exe"

[Setup]
AppId={{B2C3D4E5-F6A7-8901-BCDE-F12345678901}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Ekip
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\..\LICENSE.txt
OutputDir=output
OutputBaseFilename=EkipSetup-{#MyAppVersion}
SetupIconFile=..\..\src\Ekip.Desktop\Assets\ekip.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
turkish.BeveledLabel=Ekip Messenger Kurulum Sihirbazi
english.BeveledLabel=Ekip Messenger Setup Wizard

[CustomMessages]
turkish.ServerConfig=Sunucu Baglantisi
turkish.ServerConfigDesc=Ekip Messenger sunucusuna baglanmak icin gerekli bilgileri giriniz.
turkish.ServerAddress=Sunucu Adresi:
turkish.ServerPort=Port:
turkish.UseHttps=Guvenli Baglanti (HTTPS) Kullan
turkish.TestConnection=Baglanti Test Et
turkish.ConnectionSuccess=Sunucuya basariyla baglandi!
turkish.ConnectionFailed=Sunucuya baglanilamadi. Lutfen bilgileri kontrol ediniz.
turkish.UserPreferences=Kullanici Tercihleri
turkish.UserPreferencesDesc=Uygulama davranislarini yapilandiriniz.
turkish.StartWithWindows=Windows ile birlikte baslat
turkish.MinimizeToTray=Kapatildiginda sistem tepsisine kucult
turkish.EnableNotifications=Masaustu bildirimlerini etkinlestir
turkish.EnableSounds=Bildirim seslerini etkinlestir
turkish.DarkMode=Karanlik tema kullan
turkish.AutoUpdate=Otomatik guncellemeleri kontrol et
turkish.StartMinimized=Kucultulmus olarak baslat
turkish.ShowOfflineContacts=Cevrimdisi kisileri goster
turkish.LanguageSelect=Dil Secimi:
turkish.LaunchApp=Ekip Messenger'i baslat

english.ServerConfig=Server Connection
english.ServerConfigDesc=Enter the required information to connect to Ekip Messenger server.
english.ServerAddress=Server Address:
english.ServerPort=Port:
english.UseHttps=Use Secure Connection (HTTPS)
english.TestConnection=Test Connection
english.ConnectionSuccess=Successfully connected to server!
english.ConnectionFailed=Could not connect to server. Please check your settings.
english.UserPreferences=User Preferences
english.UserPreferencesDesc=Configure application behavior.
english.StartWithWindows=Start with Windows
english.MinimizeToTray=Minimize to system tray when closed
english.EnableNotifications=Enable desktop notifications
english.EnableSounds=Enable notification sounds
english.DarkMode=Use dark theme
english.AutoUpdate=Check for automatic updates
english.StartMinimized=Start minimized
english.ShowOfflineContacts=Show offline contacts
english.LanguageSelect=Language:
english.LaunchApp=Launch Ekip Messenger

[Types]
Name: "full"; Description: "Tam Kurulum"
Name: "compact"; Description: "Minimal Kurulum"
Name: "custom"; Description: "Ozel Kurulum"; Flags: iscustom

[Components]
Name: "main"; Description: "Ekip Messenger"; Types: full compact custom; Flags: fixed
Name: "shortcuts"; Description: "Masaustu Kisayollari"; Types: full custom

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Components: shortcuts
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Components: shortcuts
Name: "startupicon"; Description: "Windows ile birlikte baslat"; GroupDescription: "Ek Secenekler:"; Components: main

[Files]
Source: "..\..\publish\client\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--minimized"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[Registry]
; Uygulama ayarlarini kaydet
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: string; ValueName: "ServerUrl"; ValueData: "{code:GetServerUrl}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "UseHttps"; ValueData: "{code:GetUseHttpsInt}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "StartWithWindows"; ValueData: "{code:GetStartWithWindowsInt}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "MinimizeToTray"; ValueData: "{code:GetMinimizeToTrayInt}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "EnableNotifications"; ValueData: "{code:GetEnableNotificationsInt}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "EnableSounds"; ValueData: "{code:GetEnableSoundsInt}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Ekip\Messenger"; ValueType: dword; ValueName: "DarkMode"; ValueData: "{code:GetDarkModeInt}"; Flags: uninsdeletekey

[Code]
var
  // Sunucu baglanti sayfasi
  ServerPage: TWizardPage;
  ServerAddressEdit: TEdit;
  ServerPortEdit: TEdit;
  UseHttpsCheckbox: TCheckBox;
  TestButton: TButton;
  ConnectionStatusLabel: TLabel;

  // Kullanici tercihleri sayfasi
  PrefsPage: TWizardPage;
  StartWithWindowsCheckbox: TCheckBox;
  MinimizeToTrayCheckbox: TCheckBox;
  EnableNotificationsCheckbox: TCheckBox;
  EnableSoundsCheckbox: TCheckBox;
  DarkModeCheckbox: TCheckBox;
  AutoUpdateCheckbox: TCheckBox;
  StartMinimizedCheckbox: TCheckBox;
  ShowOfflineContactsCheckbox: TCheckBox;

procedure TestConnectionClick(Sender: TObject);
var
  ResultCode: Integer;
  ServerUrl: String;
begin
  if UseHttpsCheckbox.Checked then
    ServerUrl := 'https://' + ServerAddressEdit.Text + ':' + ServerPortEdit.Text
  else
    ServerUrl := 'http://' + ServerAddressEdit.Text + ':' + ServerPortEdit.Text;

  ConnectionStatusLabel.Caption := 'Baglanti test ediliyor...';
  ConnectionStatusLabel.Font.Color := clGray;

  // Basit bir HTTP istegi ile sunucuyu kontrol et
  // Not: Gercek uygulamada daha gelismis bir kontrol yapilabilir
  if Exec('powershell.exe',
    '-NoProfile -ExecutionPolicy Bypass -Command "try { $response = Invoke-WebRequest -Uri ''' + ServerUrl + '/api/health'' -TimeoutSec 5 -UseBasicParsing; exit 0 } catch { exit 1 }"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if ResultCode = 0 then begin
      ConnectionStatusLabel.Caption := CustomMessage('ConnectionSuccess');
      ConnectionStatusLabel.Font.Color := clGreen;
    end else begin
      ConnectionStatusLabel.Caption := CustomMessage('ConnectionFailed');
      ConnectionStatusLabel.Font.Color := clRed;
    end;
  end else begin
    ConnectionStatusLabel.Caption := CustomMessage('ConnectionFailed');
    ConnectionStatusLabel.Font.Color := clRed;
  end;
end;

procedure InitializeWizard;
begin
  // Sunucu Baglanti Sayfasi
  ServerPage := CreateCustomPage(wpSelectTasks,
    CustomMessage('ServerConfig'),
    CustomMessage('ServerConfigDesc'));

  // Sunucu Adresi
  with TLabel.Create(ServerPage) do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('ServerAddress');
    Left := 0;
    Top := 8;
  end;
  ServerAddressEdit := TEdit.Create(ServerPage);
  with ServerAddressEdit do begin
    Parent := ServerPage.Surface;
    Left := 0;
    Top := 28;
    Width := 300;
    Text := 'localhost';
  end;

  // Port
  with TLabel.Create(ServerPage) do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('ServerPort');
    Left := 320;
    Top := 8;
  end;
  ServerPortEdit := TEdit.Create(ServerPage);
  with ServerPortEdit do begin
    Parent := ServerPage.Surface;
    Left := 320;
    Top := 28;
    Width := 80;
    Text := '5001';
  end;

  // HTTPS Checkbox
  UseHttpsCheckbox := TCheckBox.Create(ServerPage);
  with UseHttpsCheckbox do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('UseHttps');
    Left := 0;
    Top := 64;
    Width := 300;
    Checked := True;
  end;

  // Test Button
  TestButton := TButton.Create(ServerPage);
  with TestButton do begin
    Parent := ServerPage.Surface;
    Caption := CustomMessage('TestConnection');
    Left := 0;
    Top := 100;
    Width := 150;
    Height := 25;
    OnClick := @TestConnectionClick;
  end;

  // Connection Status
  ConnectionStatusLabel := TLabel.Create(ServerPage);
  with ConnectionStatusLabel do begin
    Parent := ServerPage.Surface;
    Left := 160;
    Top := 104;
    Width := 250;
    Caption := '';
  end;

  // Ornek Sunucu Bilgileri
  with TLabel.Create(ServerPage) do begin
    Parent := ServerPage.Surface;
    Caption := 'Ornek: ekip-server.sirket.local veya 192.168.1.100';
    Left := 0;
    Top := 140;
    Font.Color := clGray;
    Font.Size := 8;
  end;

  // Kullanici Tercihleri Sayfasi
  PrefsPage := CreateCustomPage(ServerPage.ID,
    CustomMessage('UserPreferences'),
    CustomMessage('UserPreferencesDesc'));

  // Baslangiç Secenekleri
  with TLabel.Create(PrefsPage) do begin
    Parent := PrefsPage.Surface;
    Caption := 'Baslangic Secenekleri';
    Left := 0;
    Top := 0;
    Font.Style := [fsBold];
  end;

  StartWithWindowsCheckbox := TCheckBox.Create(PrefsPage);
  with StartWithWindowsCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('StartWithWindows');
    Left := 16;
    Top := 24;
    Width := 350;
    Checked := True;
  end;

  StartMinimizedCheckbox := TCheckBox.Create(PrefsPage);
  with StartMinimizedCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('StartMinimized');
    Left := 16;
    Top := 48;
    Width := 350;
    Checked := False;
  end;

  MinimizeToTrayCheckbox := TCheckBox.Create(PrefsPage);
  with MinimizeToTrayCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('MinimizeToTray');
    Left := 16;
    Top := 72;
    Width := 350;
    Checked := True;
  end;

  // Bildirim Secenekleri
  with TLabel.Create(PrefsPage) do begin
    Parent := PrefsPage.Surface;
    Caption := 'Bildirim Secenekleri';
    Left := 0;
    Top := 108;
    Font.Style := [fsBold];
  end;

  EnableNotificationsCheckbox := TCheckBox.Create(PrefsPage);
  with EnableNotificationsCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('EnableNotifications');
    Left := 16;
    Top := 132;
    Width := 350;
    Checked := True;
  end;

  EnableSoundsCheckbox := TCheckBox.Create(PrefsPage);
  with EnableSoundsCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('EnableSounds');
    Left := 16;
    Top := 156;
    Width := 350;
    Checked := True;
  end;

  // Gorunum Secenekleri
  with TLabel.Create(PrefsPage) do begin
    Parent := PrefsPage.Surface;
    Caption := 'Gorunum Secenekleri';
    Left := 0;
    Top := 192;
    Font.Style := [fsBold];
  end;

  DarkModeCheckbox := TCheckBox.Create(PrefsPage);
  with DarkModeCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('DarkMode');
    Left := 16;
    Top := 216;
    Width := 350;
    Checked := False;
  end;

  ShowOfflineContactsCheckbox := TCheckBox.Create(PrefsPage);
  with ShowOfflineContactsCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('ShowOfflineContacts');
    Left := 16;
    Top := 240;
    Width := 350;
    Checked := True;
  end;

  // Guncelleme Secenekleri
  with TLabel.Create(PrefsPage) do begin
    Parent := PrefsPage.Surface;
    Caption := 'Diger Secenekler';
    Left := 0;
    Top := 276;
    Font.Style := [fsBold];
  end;

  AutoUpdateCheckbox := TCheckBox.Create(PrefsPage);
  with AutoUpdateCheckbox do begin
    Parent := PrefsPage.Surface;
    Caption := CustomMessage('AutoUpdate');
    Left := 16;
    Top := 300;
    Width := 350;
    Checked := True;
  end;
end;

function GetServerUrl(Param: String): String;
begin
  if UseHttpsCheckbox.Checked then
    Result := 'https://' + ServerAddressEdit.Text + ':' + ServerPortEdit.Text
  else
    Result := 'http://' + ServerAddressEdit.Text + ':' + ServerPortEdit.Text;
end;

function GetUseHttpsInt(Param: String): String;
begin
  if UseHttpsCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

function GetStartWithWindowsInt(Param: String): String;
begin
  if StartWithWindowsCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

function GetMinimizeToTrayInt(Param: String): String;
begin
  if MinimizeToTrayCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

function GetEnableNotificationsInt(Param: String): String;
begin
  if EnableNotificationsCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

function GetEnableSoundsInt(Param: String): String;
begin
  if EnableSoundsCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

function GetDarkModeInt(Param: String): String;
begin
  if DarkModeCheckbox.Checked then
    Result := '1'
  else
    Result := '0';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: String;
  ConfigContent: TStringList;
begin
  if CurStep = ssPostInstall then begin
    // config.json dosyasini olustur
    ConfigFile := ExpandConstant('{app}\config.json');
    ConfigContent := TStringList.Create;
    try
      ConfigContent.Add('{');
      ConfigContent.Add('  "Server": {');
      ConfigContent.Add('    "Url": "' + GetServerUrl('') + '",');
      ConfigContent.Add('    "HubPath": "/hubs/message",');
      ConfigContent.Add('    "UseHttps": ' + LowerCase(BoolToStr(UseHttpsCheckbox.Checked)));
      ConfigContent.Add('  },');
      ConfigContent.Add('  "Preferences": {');
      ConfigContent.Add('    "StartWithWindows": ' + LowerCase(BoolToStr(StartWithWindowsCheckbox.Checked)) + ',');
      ConfigContent.Add('    "StartMinimized": ' + LowerCase(BoolToStr(StartMinimizedCheckbox.Checked)) + ',');
      ConfigContent.Add('    "MinimizeToTray": ' + LowerCase(BoolToStr(MinimizeToTrayCheckbox.Checked)) + ',');
      ConfigContent.Add('    "EnableNotifications": ' + LowerCase(BoolToStr(EnableNotificationsCheckbox.Checked)) + ',');
      ConfigContent.Add('    "EnableSounds": ' + LowerCase(BoolToStr(EnableSoundsCheckbox.Checked)) + ',');
      ConfigContent.Add('    "DarkMode": ' + LowerCase(BoolToStr(DarkModeCheckbox.Checked)) + ',');
      ConfigContent.Add('    "ShowOfflineContacts": ' + LowerCase(BoolToStr(ShowOfflineContactsCheckbox.Checked)) + ',');
      ConfigContent.Add('    "AutoUpdate": ' + LowerCase(BoolToStr(AutoUpdateCheckbox.Checked)));
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
    Result := 'True'
  else
    Result := 'False';
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  // Sunucu sayfasinda bos kontrol
  if CurPageID = ServerPage.ID then begin
    if Trim(ServerAddressEdit.Text) = '' then begin
      MsgBox('Lutfen sunucu adresini giriniz.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    if Trim(ServerPortEdit.Text) = '' then begin
      MsgBox('Lutfen port numarasini giriniz.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end;
end;
