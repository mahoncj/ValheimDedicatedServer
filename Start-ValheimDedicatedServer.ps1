<#
.SYNOPSIS
    Valheim Server Management Script.
    This script will help you easily install your valheim server on a windows machine utilizing SteamCMD.
    Prerequisites:
        1) Install SteamCMD from their website (https://developer.valvesoftware.com/wiki/SteamCMD#Downloading_SteamCMD)
        2) Update the Script with the correct locations of the directories you'll use

    Execution:
        This script has been cut up into functions so you can execute only sections of it.
        Without any parameters, the script will execute any bacukps, update the game, validate the game files, start the server.
        You can call it with parametrs to only do the update + validate, backup, or start the server. Call the script with the -help parameter to see available usages.

.EXAMPLE
    .\Start-ValheimServer
    .\Start-ValheimServer -Help
.LINK
    Author:    Chris Mahon
    Email:     chrismahon@blueflashylights.com
    Release:   20210218
#>
param(
[Alias('b')]
[switch]$backup,
[Alias('d')]
[switch]$debug,
[Alias('h')]
[switch]$help,
[Alias('i')]
[switch]$install,
[Alias('s')]
[switch]$start,
[Alias('u')]
[switch]$update
)


####################################################
#Server Setup - Update these with the correct values for your server
####################################################

$steamCmd = "C:\SteamCmd\steamcmd.exe";
$valheimDir = "C:\SteamApps\Valheim\"
$valheimBkup = "C:\SteamApps\ValheimBackup\"
$valheimSaves = "C:\Users\{ServerLogin}\AppData\LocalLow\IronGate\Valheim\"

$gameName = "Whatever You'd Like";
$worldName = "Name of your World";
$gamePass = "MUST BE 6+ Characters Long";


####################################################
#Functions used in the script
#Don't update these unless you know what you're doing
####################################################


function Start-Valheim(){
    Set-Item ENV:SteamAppId 892970
    Write-Update "Starting Valheim Server, press Ctrl+c to close server";
    $cmd = "$($valheimDir)valheim_server.exe"
    $params = "-nographics -batchmode -name `"$gameName`" -port 2456 -world `"$worldName`" -password `"$gamePass`""
    Write-Debug "Executing '$cmd $params'"
    Invoke-Expression "$cmd $params"
}

function Update-Valheim(){
    $params = "+login anonymous +force_install_dir $($valheimDir) +app_update 896660 validate +exit";
    Write-Debug "Executing '$steamCmd $params'"
    Invoke-Expression "$steamCmd $params"
}

function Write-Update($msg){
    Write-Host -ForegroundColor Yellow $msg;
}
function Write-Done(){
    $width = (Get-Host).UI.RawUI.MaxWindowSize.Width;
    Write-Host -ForegroundColor Green "[Doneski]";
    Write-Host "$("-" * $width)`n`n";
}

function Write-Short-Error ($message = $null) {
    Write-Host -ForegroundColor Red "[ERR]`n";

    if ($null -ne $message) {
        Write-Host -ForegroundColor DarkRed "$($message)`n";
    }
}

function Write-Header ($msg) {
    $width = (Get-Host).UI.RawUI.MaxWindowSize.Width;
    Write-Debug "Got width of $width"

   
    Write-Host "`n$("=" * $width)";
    Write-Host -ForegroundColor Magenta $msg
    Write-Host "$("-" * $width)`n`n";
}

function Backup-Valheim-Files ($src, $dst) {
    $date = get-date -format 'yyyyMMddHHmm'
    $bkupDir = $dst + "\" + $date;

    if ((Test-Path $src) -and (Test-Path $dst) -and (-not (Test-Path $bkupDir))){
        New-Item -ItemType Directory -Path $dst -Name $date;
        Copy-Item -path $src -recurse -destination $bkupDir;
    } else {
        $errMsg = "";
        if (-not (Test-Path $src)) { $errMsg += "Could not find $src `r`n"; }
        if (-not (Test-Path $dst)) { $errMsg += "Could not find $dst `r`n"; }
        if ((Test-Path $bkupDir)) { $errMsg += "$bkupDir exists. Did you create a backup recently? `r`n"; }
        Write-Short-Error "$errMsg `r`nPlease fix the issues and/or update the script variables";
    }
}


####################################################
#Start Script
####################################################

Clear-Host


Write-Header "Valheim Updater";
if ($help){
    Write-Host "This is a quick script to manage your Valheim server via powershell.`r`n";

    Write-Host "`t-B -Backup`tCreates a backup of the game files (worlds)";
    Write-Host "`t-D -Debug`tPrints out helpful statements";
    Write-Host "`t-H -Help`tPrints out this menu";
    Write-Host "`t-I -Install`tInstalls and verifies the game using SteamCMD";
    Write-Host "`t-S -Start`tStarts the server";
    Write-Host "`t-U -Update`tUpdates and verifies the game using SteamCMD";
    Write-Host "`t`t`t(No Flags) Runs a backup, then attempts to update, finally starts the server";
    return;
}
if ($debug){ $DebugPreference = 'Continue'; Write-Debug "Switches: Install: $install Update: $update Start: $start Debug: $debug"; }

if ($backup){
    Backup-Valheim-Files $valheimSaves $valheimBkup;
    Write-Done;
    return;
}
if ($install -or $update){
    Update-Valheim;
    Write-Done;
    return;
}
if ($start){
    Start-Valheim;
    Write-Done;
    return;
}


try {
    Write-Update "Backing up data";
    Backup-Valheim-Files $valheimSaves $valheimBkup;
    Write-Done;
    Write-Update "Updating Valheim";
    Update-Valheim;
    Write-Done;
    Write-Update "Starting Valheim";
    Start-Valheim;
    Write-Done;
    Write-Done;
} catch {
    Write-Short-Error $_.Exception.Message;
    Read-Host "Press the any key to exit";
}