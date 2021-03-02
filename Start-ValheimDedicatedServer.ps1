<#

.SYNOPSIS
    
    Starts the Valheim Dedicated Server process

.EXAMPLE

    .\Start-ValheimDedicatedServer.ps1 -PathToSteamCMD C:\steamcmd -PathToValheimBackup C:\valheimbackup -PathToValheimInstall C:\valheim

.LINK

    Author:    Chris Mahon
    Email:     chrismahon@blueflashylights.com
    Release:   20210218

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
    $lines += "START VALHEIM DEDICATED SERVER V2.0";
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

        $irongate = $home + '\AppData\LocalLow\IronGate';
    
        $TestIrongate = test-path -path $Irongate;
    
        if ($TestIrongate -eq $true) {
    
            copy-item -path $Irongate -recurse -destination "$PathToValheimBackup\Backups\$Date\IronGate";
        }

        else {
    
            write-host;
            write-host "Could not find the IronGate folder containing your worlds. If this is not a fresh install, please check that the IronGate folder exists within $home\AppData\LocalLow." -foregroundcolor yellow;
            write-host;

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

    $TestValheimInstall = test-path -path "$PathToValheimInstall";

    if ($TestValheimInstall -eq $true) {

        $currentdirectory = get-location;

        $null = set-location -path $PathToSteamCMD;

        $null = .\steamcmd.exe +login anonymous +force_install_dir $PathToValheimInstall +app_update 896660 validate +exit;
    
        $null = set-location -path $currentdirectory;

    }

    else {

        write-host;
        write-host "Valheim Dedicated Server was not found within ""$PathToValheimInstall"". Would you like to download it?" -foregroundcolor yellow;
        write-host;
    
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "This will download SteamCMD to ""$PathToSteamCMD"".";
    
        $quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "This will terminate the script.";
    
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $quit);
    
        $result = $Host.ui.PromptForChoice($null, $null, $options, 0);
    
            if ($result -eq 1) {
    
                exit;
    
            }

        $currentdirectory = get-location;
        
        $null = set-location -path $PathToSteamCMD;

        $null = .\steamcmd.exe +login anonymous +force_install_dir $PathToValheimInstall +app_update 896660 validate +exit;

        $null = set-location -path $currentdirectory;
        
        $script:NewValheimInstall = $true;
    }

}

function backup_headless_server() {

    $TestHeadlessServer = test-path -path "$PathToValheimInstall\start_headless_server.bat";

    if ($TestHeadlessServer -eq $true) {

        $null = copy-item -path "$PathToValheimInstall\start_headless_server.bat" -destination $PathToValheimBackup;
    }

    else {

        write-host;
        write-host "The start_headless_server.bat file was not located within ""$PathToValheimInstall"" directory." -foregroundcolor yellow;
        write-host;

    }

}

function restore_headless_server () {

    $TestHeadlessServerBackup = test-path -path "$PathToValheimBackup\start_headless_server.bat";

    if ($TestHeadlessServerBackup -eq $true) {

        $null = copy-item -path "$PathToValheimBackup\start_headless_server.bat" -destination "$PathToValheimInstall\start_headless_server.bat";
    }

    else {

        write-host;
        write-host "No previous start_headless_server.bat file detected within the ""$PathToValheimBackup"" directory. This is a fresh install." -foregroundcolor yellow;
        write-host;
    }
}

function check_valheim_firewall_rules () {

    $ValheimTCPInbound = Get-NetFirewallRule -Name "VALHEIM_TCP_IN" -ErrorAction SilentlyContinue;

    if ($ValheimTCPInbound.Enabled -ne "True") {

        write-host;
        write-host "Adding the following Firewall rule: ""VALHEIM_TCP_IN"" - Inbound - TCP - 2456-2458" -foregroundcolor green;
        write-host;
        $null = New-NetFirewallRule -Name "VALHEIM_TCP_IN" -DisplayName "VALHEIM_TCP_IN" -Direction Inbound -LocalPort 2456-2458 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue;

    }
    
    $ValheimUDPInbound = Get-NetFirewallRule -Name "VALHEIM_UDP_IN" -ErrorAction SilentlyContinue;

    if ($ValheimUDPInbound.Enabled -ne "True") {

        write-host;
        write-host "Adding the following Firewall rule: ""VALHEIM_UDP_IN"" - Inbound - UDP - 2456-2458" -foregroundcolor green;
        write-host;
        $null = New-NetFirewallRule -Name "VALHEIM_UDP_IN" -DisplayName "VALHEIM_UDP_IN" -Direction Inbound -LocalPort 2456-2458 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue;
    
    }

    $ValheimTCPOutbound = Get-NetFirewallRule -Name "VALHEIM_TCP_OUT" -ErrorAction SilentlyContinue;

    if ($ValheimTCPOutbound.Enabled -ne "True") {

        write-host;
        write-host "Adding the following Firewall rule: ""VALHEIM_TCP_OUT"" - Outbound - TCP - 2456-2458" -foregroundcolor green;
        write-host;
        $null = New-NetFirewallRule -Name "VALHEIM_TCP_OUT" -DisplayName "VALHEIM_TCP_OUT" -Direction Outbound -LocalPort 2456-2458 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue;
    
    }
    
    $ValheimUDPOutbound = Get-NetFirewallRule -Name "VALHEIM_UDP_OUT" -ErrorAction SilentlyContinue;

    if ($ValheimUDPOutbound.Enabled -ne "True") {

        write-host;
        write-host "Adding the following Firewall rule: ""VALHEIM_UDP_OUT"" - Outbound - UDP - 2456-2458" -foregroundcolor green;
        write-host;
        $null = New-NetFirewallRule -Name "VALHEIM_UDP_OUT" -DisplayName "VALHEIM_UDP_OUT" -Direction Outbound -LocalPort 2456-2458 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue;

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

    ui_start_status "Restoring existing Valheim start_headless_server.bat file to ""$PathToValheimInstall""";

    restore_headless_server;

    ui_complete_status;

    ui_start_status "Checking Valheim Dedicated Server firewall rules";

    check_valheim_firewall_rules;

    ui_complete_status;

    ui_start_status "Starting Valheim Dedicated Server";

    if ($script:NewValheimInstall -eq $true) {

        write-host;
        write-host "New Valheim Dedicated Install located within ""$PathToValheimInstall"". Please edit the start_headless_server.bat file within ""$PathToValheimInstall"" to provide your world details and password and run this script again!" -ForegroundColor yellow;
        write-host;
        exit;
    }

    $currentdirectory = get-location;

    $null = set-location -path $PathToValheimInstall;

    $null = start-process .\start_headless_server.bat;

    $null = set-location -path $currentdirectory;

    ui_complete_status;

} catch {

    ui_error_status $_.exception.message;

    read-host "Press any key to exit...";

    write-host;

}
