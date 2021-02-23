<#

.SYNOPSIS
    
    Starts the Valheim Dedicated Server process

    Dependencies (adjust these variables to match your install):
        1) $SteamCMD - SteamCMD installed and located within F:\SteamCMD
        2) $Valheim - Valheim Dedicated Server installed via SteamCMD and located within F:\Valheim
        3) $ValheimBackup - A directory where I store weekly backups of the World and a backup of the start_headless_server.bat file
        4) $StartHeadlessServer - This is my modified version of the start_headless_server.bat file which contains my World info and password.

.EXAMPLE

    .\Start-ValheimServer

.LINK

    Author:    Chris Mahon
    Email:     chrismahon@blueflashylights.com
    Release:   20210218

#>

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
    $lines += "START VALHEIM DEDICATED SERVER V1.0";
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

    $date = get-date -format 'yyyyMMddHHmm'

    $irongate = $home + '\AppData\LocalLow\IronGate';

    $TestIrongate = test-path -path $Irongate;

    if ($TestIrongate -eq $true) {

        copy-item -path $Irongate -recurse -destination "$ValheimBackup\Backups\$Date\IronGate"
    }
    else {

        write-host "Could not find the IronGate folder containing your worlds. Please check that the IronGate folder exists within $home\AppData\LocalLow." -foregroundcolor red

    }

}

try {

    ### Modify the below variables to accomodate your specific server install

    $SteamCMD = "F:\SteamCMD";

    $Valheim = "F:\Valheim";

    $ValheimBackup = "F:\ValheimServerBackup";

    $StartHeadlessServer = "F:\ValheimServerBackup\start_headless_server.bat";

    ### Perform Start Valheim Dedicated Server

    ui_write_header "Valheim Dedicated Server - Start Server";

    ui_start_status "Backing up IronGate Directory";

    backup_valheim_files;

    ui_complete_status;
    
    ui_start_status "Checking for Updates";

    set-location -path $SteamCMD;

    .\steamcmd.exe +login anonymous +force_install_dir $Valheim +app_update 896660 validate +exit;

    ui_complete_status;

    ui_start_status "Restoring Valheim Start_Headless_Server Script File";

    copy-item $StartHeadlessServer -destination $Valheim -force;

    ui_complete_status;

    ui_start_status "Starting Valheim Dedicated Server";

    set-location $Valheim;

    start-process .\start_headless_server.bat;

    ui_complete_status;

} catch {

    ui_error_status $_.exception.message;

    read-host "Press any key to exit...";

    write-host;

}
