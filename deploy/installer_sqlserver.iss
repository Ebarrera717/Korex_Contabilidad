; ============================================================================
; PROYECTO: KOREX_CONTABILIDAD
; INSTALADOR PRINCIPAL - MOTOR SQL SERVER
; ============================================================================

#define MyAppName "Korex_Contabilidad (SQL Server)"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Rubiel Gelis"

[Setup]
AppId={{E8539643-7B26-5E7F-AF3C-9D5F82C310B2}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Korex_Contabilidad_SQL
DefaultGroupName=Korex_Contabilidad
OutputDir=..\dist
OutputBaseFilename=Korex_Contabilidad_Setup_SqlServer
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git\*,.next\cache\*,dist\*,*.log,node_modules\.cache\*,*.tmp"

; Protección Absoluta del Archivo .env
Source: "..\.env.example"; DestDir: "{app}"; DestName: ".env"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\iniciar-next.bat"; IconFilename: "{app}\public\favicon.ico"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\iniciar-next.bat"; Tasks: desktopicon; IconFilename: "{app}\public\favicon.ico"

[Run]
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\gen_schema_json.js"; StatusMsg: "Configurando esquemas de base de datos SQL Server..."; Flags: runhidden
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\service_installer.js install"; StatusMsg: "Instalando servicio de Windows..."; Flags: runhidden
Filename: "http://localhost:3002"; Flags: shellexec runasoriginaluser postinstall nowait; Description: "Abrir Korex_Contabilidad (SQL Server) en el navegador"
