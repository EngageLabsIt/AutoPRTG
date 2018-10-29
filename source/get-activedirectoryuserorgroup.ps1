$currentFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent
. "$currentFolder\functions.ps1"



Clear-Host;
$error.Clear();

$configurationsFolder = "Configurations";
$probeSettingFile = "probe-settings.json";

$configurationsPath = Join-Path -Path $CurrentFolder -ChildPath $configurationsFolder;

Write-Host "This script will get the list of ActiveDirectoryUserOrGroup in PRTG. Based on the probe file <$probeSettingFile> in the folder:" -ForegroundColor White;
Write-Host "$configurationsPath" -ForegroundColor White;
Write-Host "ATTENTION: you must use a user with administrator grant to get the complete list!" -ForegroundColor Yellow;
$mainOption = pause -Message "Press ENTER to continue..." -ForegroundColor White;
if ($mainOption -ne "" -and $mainOption.VirtualKeyCode -ne "13")
{
    exit;
}

# Install PRTG API
Write-Host "Checking if PrtgAPI module already exists..." -ForegroundColor Gray;
if (Get-Module -ListAvailable -Name PrtgAPI) {
    Write-Host "The module PrtgAPI already exists. No user action required." -ForegroundColor Gray;
} else {
    Write-Host "Install PrtgAPI..." -ForegroundColor Gray;
	Install-Package PrtgAPI | Out-Null;
    Write-Host "PrtgAPI Installed successfully..." -ForegroundColor Gray;
}
Write-Host 


# reading probe settings (json file)
Write-Host "Loading probe settings from file: $probeSettingFile" -ForegroundColor Gray

$config = Get-Sensor-Config -ConfigFileName $probeSettingFile -CurrentFolder $configurationsPath
$PRTGHost = $config.PrtgHttpHost
$username = $config.PrtgUsername
$password = $config.PrtgPassword
$deviceName = $config.DeviceName
$isvalidjson = $config.IsValidJson
if ($isvalidjson -eq $false)
{
    Write-Host "Invalid Id reference inside probe settings file. Please check <$probeSettingFile> file." -ForegroundColor Red
    exit;
}

if ($PRTGHost.Substring(0, 4) -ne "http")
{
    $PRTGUrl = "https:\\$PRTGHost"
}
else
{
    $PRTGUrl = $PRTGHost
}


# connecting to PRTG server
Write-Host "Connecting to PRTG server '$PRTGHost' ..." -ForegroundColor Gray
Connect-PrtgServer $PRTGHost -Force (New-Credential $username $password)
if ($error.Count -ne 0) 
{
    $error
    Write-Host "Connecting to PRTG Failed!" -ForegroundColor Red;
    exit;
}
Write-Host "Connected" -ForegroundColor White

Write-Host "---------------------------------------"

Get-Object | where { $_.Type -eq "ActiveDirectoryUserOrGroup" }

Write-Host 
Write-Host "Disconnecting..." -ForegroundColor Gray;
Disconnect-PrtgServer;
Write-Host "Disconnected!" -ForegroundColor White;
