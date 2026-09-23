; ============================================================================
; PROYECTO: KOREX_CONTABILIDAD
; ACTUALIZADOR - MOTOR SQL SERVER
; ============================================================================

#define MyAppName "Korex_Contabilidad (SQL Server)"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Rubiel Gelis"

[Setup]
AppId={{E8539643-7B26-5E7F-AF3C-9D5F82C310B2}
AppName={#MyAppName} (Actualización)
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Korex_Contabilidad_SQL
DefaultGroupName=Korex_Contabilidad
OutputDir=..\dist
OutputBaseFilename=Korex_Contabilidad_Update_SqlServer
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
DirExistsWarning=no
DisableDirPage=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
; Archivos actualizables (EXCLUYE estrictamente .env)
Source: "..\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".env,.git\*,.next\cache\*,dist\*,*.log,node_modules\.cache\*,*.tmp"

[Run]
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\gen_schema_json.js"; StatusMsg: "Aplicando actualizaciones SQL Server..."; Flags: runhidden
Filename: "http://localhost:3002"; Flags: shellexec runasoriginaluser postinstall nowait; Description: "Abrir Korex_Contabilidad actualizado"
