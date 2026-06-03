; Instalador do Petra ERP — gerado para distribuicao ao dono
#define MyAppName "Petra ERP"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Petra"
#define MyAppExeName "petra_erp.exe"
#define BuildDir "..\petra_erp\build\windows\x64\runner\Release"
#define IconFile "..\petra_erp\windows\runner\resources\app_icon.ico"
#define OutDir "..\deploy\download"

[Setup]
AppId={{8F3A1C20-7E4B-4D9A-9C1E-PETRAERP0001}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Petra ERP
DefaultGroupName=Petra ERP
DisableProgramGroupPage=yes
OutputDir={#OutDir}
OutputBaseFilename=petra-setup
SetupIconFile={#IconFile}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na area de trabalho"; GroupDescription: "Atalhos:"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir o Petra ERP"; Flags: nowait postinstall skipifsilent
