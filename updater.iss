#define AppName "Folder Customizer"
#define LocalManifestFile "{app}\manifest.json"
#define RemoteManifestURL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json"
#define LatestInstallerURL "https://github.com/Deadbush225/Folder-Customizer/releases/latest/download/FolderCustomizerSetup-x64.exe"

[Setup]
AppName={#AppName}
AppVersion=1.0.0
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
OutputBaseFilename=Updater
SetupIconFile=D:\System\Coding\Projects\folder-customizer\packages\com.mainprogram\data\bin\Icons\Folder Customizer.ico
SolidCompression=yes
WizardStyle=modern

[Code]
function DownloadFile(URL: string): string;
var
    TempFilePath: string;
begin
    if DownloadTemporaryFile(URL, TempFilePath) then
        Result := TempFilePath
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
        StartPos := PosEx('"', JSON, StartPos + Length(Key) + 3);
        EndPos := PosEx('"', JSON, StartPos + 1);
        Result := Copy(JSON, StartPos + 1, EndPos - StartPos - 1);
    end
    else
        Result := '';
end;

procedure InitializeUpdate();
var
    LocalManifest, RemoteManifest: string;
    LocalVersion, RemoteVersion: string;
    RemoteManifestPath: string;
    InstallerPath: string;
    ResultCode: Integer;
begin
    // Download the remote manifest
    RemoteManifestPath := DownloadFile('{#RemoteManifestURL}');
    if RemoteManifestPath = '' then
        Exit;

    // Read the local manifest
    if FileExists(ExpandConstant('{#LocalManifestFile}')) then
        LoadStringFromFile(ExpandConstant('{#LocalManifestFile}'), LocalManifest)
    else
        LocalManifest := '{"version": "0.0.0"}'; // Default if no local manifest exists

    // Read the remote manifest
    LoadStringFromFile(RemoteManifestPath, RemoteManifest);

    // Extract version numbers
    LocalVersion := GetJSONValue(LocalManifest, 'version');
    RemoteVersion := GetJSONValue(RemoteManifest, 'version');

    // Compare versions
    if CompareVersions(LocalVersion, RemoteVersion) < 0 then
    begin
        MsgBox('A new version is available: ' + RemoteVersion, mbInformation, MB_OK);

        // Download the latest installer
        InstallerPath := DownloadFile('{#LatestInstallerURL}');
        if InstallerPath <> '' then
        begin
            // Run the installer
            if Exec(InstallerPath, '', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
                MsgBox('Update installed successfully!', mbInformation, MB_OK)
            else
                MsgBox('Failed to run the installer.', mbError, MB_OK);
        end
        else
            MsgBox('Failed to download the latest installer.', mbError, MB_OK);
    end
    else
        MsgBox('You already have the latest version: ' + LocalVersion, mbInformation, MB_OK);
end;

[Run]
Filename: "{app}\Updater.exe"; Description: "Check for Updates"; Flags: postinstall skipifsilent