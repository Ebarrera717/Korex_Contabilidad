; ============================================================================
; PROYECTO: KOREX_CONTABILIDAD
; INSTALADOR PRINCIPAL - MOTOR POSTGRESQL
; ============================================================================

#define MyAppName "Korex_Contabilidad"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Rubiel Gelis"
#define MyAppExeName "KorexContabilidad.exe"

[Setup]
AppId={{D1429532-6A15-4D6F-9E2B-8C4E71B209A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\dist
OutputBaseFilename=Korex_Contabilidad_Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Archivos principales de la aplicación
Source: "..\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git\*,.next\cache\*,dist\*,*.log,node_modules\.cache\*,*.tmp"

; Protección Absoluta del Archivo .env (Solo si no existe, nunca se desinstala)
Source: "..\.env.example"; DestDir: "{app}"; DestName: ".env"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\iniciar-next.bat"; IconFilename: "{app}\public\favicon.ico"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\iniciar-next.bat"; Tasks: desktopicon; IconFilename: "{app}\public\favicon.ico"

[Run]
; Inicialización de base de datos e instalación del servicio
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\gen_schema_json.js"; StatusMsg: "Configurando esquemas de base de datos..."; Flags: runhidden
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\service_installer.js install"; StatusMsg: "Instalando servicio de Windows..."; Flags: runhidden
Filename: "http://localhost:3002"; Flags: shellexec runasoriginaluser postinstall nowait; Description: "Abrir Korex_Contabilidad en el navegador"
