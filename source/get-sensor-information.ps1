
######setup details, access related.
$PRTGHost = "https://monitoring.odissea.at"
$username = "prtgApiUser"

######################################################
# MAIN
######################################################

Clear-Host


Write-Host "PRTG Get Sensor information" -ForegroundColor Yellow
Write-Host 

Write-Host "Check if PrtgAPI exists..."
if (Get-Module -ListAvailable -Name PrtgAPI) {
    Write-Host "The module already exists."
} else {
    Write-Host "Install PrtgAPI..."
	Install-Package PrtgAPI
}
Write-Host "--------------------------"
Write-Host 

$password = Read-host -AsSecureString -Prompt "Insert the password to get access to PRTG:"
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
#HACK for test:
#$password = "??????????????????"

#$DeviceName = Read-host -Prompt "Insert the device name"
##HACK for test:
##$DeviceName = "a0p2-sql01"
#if ($DeviceName -eq "")
#{
#    Write-Host "Device cannot be empty!" -ForegroundColor Red
#    exit
#}

#Connect
Connect-PrtgServer $PRTGHost (New-Credential $username $password)

#$DevicesFound = Get-Device $DeviceName
#
#if ($DevicesFound.Length -lt 1)
#{
#    Write-Host "Device '$($DeviceName)' not found!" -ForegroundColor Red
#    Disconnect-PrtgServer
#    exit
#}
#
#if ($DevicesFound.Length -gt 1)
#{
#    Write-Host "Found more than one device with name '$($DeviceName)'!" -ForegroundColor Red
#    Disconnect-PrtgServer
#    exit
#}
#
#$DeviceFound = $DevicesFound | Select -First 1
#
#Write-Host "Target device: Name = '$($DeviceFound.Name)' Id = $($DeviceFound.Id)"
#Write-Host


#TODO Use sensor Name
#$DeviceName = Read-host -Prompt "Insert the Sensor Id"
#HACK for test:
$SensorId = 78594


###############
# Passaggi iniziali per ottenere le informazioni per scrivere lo script per creare un nuovo sensore:

# Per esportare tutte le informazioni di un sensore su file (mi serve per capire le sue proprietà)
#Get-Sensor -Id $SensorId | Export-Csv -Path C:\__Workspaces\Customers\OdisseaCom\Database\Environment\Baselines\CreateSensors\sensorproperty.csv

# Per ottenere le proprietà di un sensore 
Get-Sensor -Id $SensorId | Select-Object -Property Id,Name,Type,Tags,Priority,counters

## To get the channel sensor information 
Get-Channel -SensorId $SensorId | Select-Object -Property Id,Name,UpperErrorLimit,UpperWarningLimit,LowerErrorLimit,LowerWarningLimit,ErrorLimitMessage,WarningLimitMessage

Disconnect-PrtgServer
