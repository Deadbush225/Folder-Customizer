#define AppName "Folder Customizer"
#define MyAppVersion "0.0.3"
#define LocalManifestFile "{src}\manifest.json"
#define RemoteManifestURL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json"
#define LatestInstallerURL "https://github.com/Deadbush225/Folder-Customizer/releases/latest/download/FolderCustomizerSetup-x64.exe"

[Setup]
AppName={#AppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
OutputBaseFilename=Updater
SetupIconFile=.\packages\com.mainprogram\data\bin\Icons\Folder Customizer.ico
SolidCompression=yes
WizardStyle=modern
OutputDir={#SourcePath}

[Code]
function DownloadFile(URL: string): string;
var
    TempFilePath: string;
    DownloadResult: Int64;
begin
    TempFilePath := ExtractFileName(URL);
    DownloadResult := DownloadTemporaryFile(URL, TempFilePath, '', nil);
    // MsgBox(ExpandConstant('{tmp}'), mbInformation, MB_OK);
    if DownloadResult > 0 then
        Result := ExpandConstant('{tmp}') + '\' + TempFilePath
    else
    begin
        MsgBox('Failed to download file: ' + URL, mbError, MB_OK);
        Result := '';
    end;
end;

function CompareVersions(LocalVersion, RemoteVersion: string): Integer;
begin
    Result := CompareStr(LocalVersion, RemoteVersion);
end;

function GetJSONValue(JSON, Key: string): string;
var
    StartPos, EndPos: Integer;
begin
    StartPos := Pos('"' + Key + '":', JSON);
    if StartPos > 0 then
    begin
        // Move StartPos to the first quote after the key
        StartPos := Pos('"', Copy(JSON, StartPos + Length(Key) + 3, MaxInt)) + StartPos + Length(Key) + 2;
        EndPos := Pos('"', Copy(JSON, StartPos + 1, MaxInt)) + StartPos;
        Result := Copy(JSON, StartPos + 1, EndPos - StartPos - 1);
    end
    else
        Result := '';
end;

procedure InitializeUpdate();
var
    LocalManifest: AnsiString;
    RemoteManifest: AnsiString;
    LocalVersion: string;
    RemoteVersion: string;
    RemoteManifestPath: string;
    InstallerPath: string;
    ResultCode: Integer;
begin
    // Download the remote manifest
    
    RemoteManifestPath := DownloadFile('{#RemoteManifestURL}');
    if RemoteManifestPath = '' then
        Exit;
    
    // Read the local manifest
    // MsgBox(ExpandConstant('{#LocalManifestFile}'), mbInformation, MB_OK);
    if FileExists(ExpandConstant('{#LocalManifestFile}')) then
    begin
        // MsgBox('Exists', mbInformation, MB_OK);
        LoadStringFromFile(ExpandConstant('{#LocalManifestFile}'), LocalManifest);
        // MsgBox(LocalManifest, mbInformation, MB_OK);
    end
    else
        LocalManifest := '{"version": "0.0.0"}'; // Default if no local manifest exists

    // Read the remote manifest
    LoadStringFromFile(RemoteManifestPath, RemoteManifest);

    // Extract version numbers
    LocalVersion := GetJSONValue(LocalManifest, 'version');
    RemoteVersion := GetJSONValue(RemoteManifest, 'version');
    // MsgBox(LocalVersion + ' < ' + RemoteVersion, mbInformation, MB_OK);
    
    // Compare versions
    if CompareVersions(LocalVersion, RemoteVersion) < 0 then
    begin
        MsgBox('A new version is available: ' + RemoteVersion, mbInformation, MB_OK);

        // Download the latest installer
        InstallerPath := DownloadFile('{#LatestInstallerURL}');
        if InstallerPath <> '' then
        begin
            // Run the installer
            if Exec(InstallerPath, '', '', SW_SHOWNORMAL, ewNoWait, ResultCode) then
            else
                MsgBox('Failed to run the installer.', mbError, MB_OK);
        end
        else
            MsgBox('Failed to download the latest installer.', mbError, MB_OK);
    end
    // else
        // MsgBox('You already have the latest version: ' + LocalVersion, mbInformation, MB_OK);
end;

function InitializeSetup(): Boolean;
begin
    InitializeUpdate(); // Call the updater
    Result := False; // Continue with the installation
end;

[Run]
Filename: "{app}\Updater.exe"; Description: "Check for Updates"; Flags: postinstall skipifsilent










