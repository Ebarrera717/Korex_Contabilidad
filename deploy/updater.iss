; ============================================================================
; PROYECTO: KOREX_CONTABILIDAD
; ACTUALIZADOR - MOTOR POSTGRESQL
; ============================================================================

#define MyAppName "Korex_Contabilidad"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Rubiel Gelis"

[Setup]
AppId={{D1429532-6A15-4D6F-9E2B-8C4E71B209A1}
AppName={#MyAppName} (Actualización)
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=..\dist
OutputBaseFilename=Korex_Contabilidad_Update
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
DirExistsWarning=no
DisableDirPage=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
; Archivos actualizables (EXCLUYE estrictamente .env para no sobrescribir credenciales)
Source: "..\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".env,.git\*,.next\cache\*,dist\*,*.log,node_modules\.cache\*,*.tmp"

[Run]
; Ejecución incremental del actualizador SQL sin destruir datos
Filename: "{app}\node.exe"; Parameters: "{app}\deploy\gen_schema_json.js"; StatusMsg: "Aplicando actualizaciones de base de datos..."; Flags: runhidden
Filename: "http://localhost:3002"; Flags: shellexec runasoriginaluser postinstall nowait; Description: "Abrir Korex_Contabilidad actualizado"
