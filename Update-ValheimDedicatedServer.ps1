<#

.SYNOPSIS
    
    This will stop the running valheim_server process, backup the worlds, backup the start_headless_server.bat file, and proceed with updating Valheim Dedicated Server.

    To run this script, you must have SteamCMD, Valheim Dedicated Server previously installed, and provide a path to backup existing files to.

.EXAMPLE

    .\Update-ValheimDedicatedServer.ps1 -PathToSteamCMD C:\steamcmd -PathToValheimBackup C:\valheimbackup -PathToValheimInstall C:\valheim

.LINK

    Author:    Chris Mahon
    Email:     chrismahon@blueflashylights.com
    Release:   20210303

#>

[CmdletBinding()]
Param (

    [parameter(
        mandatory=$true,
        position=0)
    ]
    [alias('steamCmd')]
    [string] $PathToSteamCMD=$null,

    [parameter(
        mandatory=$true,
        position=1)
    ]
    [alias('valheimBackup')]
    [string] $PathToValheimBackup=$null,

    [parameter(
        mandatory=$true,
        position=2)
    ]
    [alias('valheimInstall')]
    [string] $PathToValheimInstall=$null

);

$ErrorActionPreference = 'Stop';

function ui_start_status ($message) {

    write-host;
    write-host ("$($message) ... ".PadRight(114)) -NoNewline;

}

function ui_complete_status () {

    write-host '[OK]' -foregroundcolor green;

}

function ui_error_status ($message = $null) {

    write-host "[ERR]" -foregroundcolor red;
    write-host;

    if ($null -ne $message) {

        write-host $message -foregroundcolor red;
        write-host;

    }

}

function ui_write_header ($title) {

    clear-host;

    $lines = @();
    $lines += "UPDATE VALHEIM DEDICATED SERVER V1.0";
    $lines += "";
    $lines += "THIS SCRIPT IS STILL IN DEVELOPMENT";
    
    write-host;
    write-host;

    $color = "yellow";

    foreach ($line in $lines) {

        write-host "$($line)".padleft(($host.ui.rawui.windowsize.width / 2) + $line.length - ($line.length / 2)) -foregroundcolor $color;

        $color = "gray";

    }
    
    write-host;
    write-host;
    write-host;

    write-host $title -foregroundcolor magenta;

}

function backup_valheim_files () {

    if ($PathToValheimBackup) {

        $date = get-date -format 'yyyyMMddHHmm';

        $ValheimWorlds = $home + '\AppData\LocalLow\IronGate\Valheim\worlds';
    
        $TestValheimWorlds = test-path -path $ValheimWorlds;
    
        if ($TestValheimWorlds -eq $true) {
    
            copy-item -path $ValheimWorlds -recurse -destination "$PathToValheimBackup\Backups\$Date\Worlds";
        }

        else {
    
            write-host;
            write-host "Could not find the $env:userprofile/AppData/LocalLow/IronGate/Valheim directory containing your existing worlds. Exiting..." -foregroundcolor red;
            write-host;
            exit;

        }
    
    }

}

function check_steamcmd () {

    $TestSteamCMD = test-path -path "$PathToSteamCMD\steamcmd.exe";

    if ($TestSteamCMD -ne $true) {

        write-host;
        write-host "SteamCMD was not found within ""$PathToSteamCMD"". Would you like to download it?" -foregroundcolor yellow;
        write-host;
    
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "This will download SteamCMD to ""$PathToSteamCMD"".";
    
        $quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "This will terminate the script.";
    
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $quit);
    
        $result = $Host.ui.PromptForChoice($null, $null, $options, 0);
    
            if ($result -eq 1) {
    
                exit;
    
            }

        $null = new-item -itemtype directory -Path $PathToSteamCMD;

        $null = invoke-webrequest -uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -method "GET"  -outfile "$PathToSteamCMD\steamcmd.zip";

        $null = expand-archive -path "$PathToSteamCMD\steamcmd.zip" -DestinationPath $PathToSteamCMD;
        
    }

}

function update_valheim () {

    $ValheimServerProcess = get-process -name "valheim_server" -ErrorAction SilentlyContinue;

    if ($ValheimServerProcess) {

        $null = stop-process -name "valheim_server";

    }

    $TestValheimInstall = test-path -path "$PathToValheimInstall";

    if ($TestValheimInstall -eq $true) {

        $currentdirectory = get-location;

        $null = set-location -path $PathToSteamCMD;

        $null = .\steamcmd.exe +login anonymous +force_install_dir $PathToValheimInstall +app_update 896660 validate +exit;
    
        $null = set-location -path $currentdirectory;

    }

    else {

        write-host;
        write-host "Valheim Dedicated Server was not found within ""$PathToValheimInstall"". Exiting..." -foregroundcolor red;
        write-host;
        exit;
    
    }

}

function backup_headless_server() {

    $TestHeadlessServer = test-path -path "$PathToValheimInstall\start_headless_server.bat";

    if ($TestHeadlessServer -eq $true) {

        $null = copy-item -path "$PathToValheimInstall\start_headless_server.bat" -destination $PathToValheimBackup;
    }

    else {

        write-host;
        write-host "The start_headless_server.bat file was not located within ""$PathToValheimInstall"" directory. Exiting..." -foregroundcolor red;
        write-host;
        exit;

    }

}

function restore_headless_server () {

    $TestHeadlessServerBackup = test-path -path "$PathToValheimBackup\start_headless_server.bat";

    if ($TestHeadlessServerBackup -eq $true) {

        $null = copy-item -path "$PathToValheimBackup\start_headless_server.bat" -destination "$PathToValheimInstall\start_headless_server.bat";
    }

    else {

        write-host;
        write-host "No previous start_headless_server.bat file detected within the ""$PathToValheimBackup"" directory. Exiting..." -foregroundcolor red;
        write-host;
        exit;
    }
}

try {

    ### Perform Start Valheim Dedicated Server

    ui_write_header "Valheim Dedicated Server - Start Server";

    ui_start_status "Checking for SteamCMD";

    check_steamcmd;

    ui_complete_status;

    ui_start_status "Backing up IronGate directory to ""$PathToValheimBackup""";

    backup_valheim_files;

    ui_complete_status;

    ui_start_status "Backing up start_headless_server.bat file to ""$PathToValheimBackup""";

    backup_headless_server;

    ui_complete_status;
    
    ui_start_status "Updating Valheim Dedicated Server";

    update_valheim;

    ui_complete_status;

    ui_start_status "Restoring Existing Valheim start_headless_server.bat file to ""$PathToValheimInstall""";

    restore_headless_server;

    ui_complete_status;

    ui_start_status "Starting Valheim Dedicated Server";
    
    $currentdirectory = get-location;

    $null = set-location -path $PathToValheimInstall;

    $null = Start-Process .\start_headless_server.bat;

    $null = set-location -path $currentdirectory;
   
    ui_complete_status;

} catch {

    ui_error_status $_.exception.message;

    read-host "Press any key to exit...";

    write-host;

}
