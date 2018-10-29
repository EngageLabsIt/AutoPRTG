$currentFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent
. "$currentFolder\functions.ps1"

Clear-Host;
$error.Clear();

# !!! WARNING !!! This setting should be changed only by an admin. Removing a sensor will delete all its related history!
# set this to true when you want to remove a previously created sensor
$deleteMatchingSensors = $false; 
$configurationsFolder = "Configurations";
$probeSettingFile = "probe-settings.json";
$configFilter = "config*.json";

$configurationsPath = Join-Path -Path $CurrentFolder -ChildPath $configurationsFolder;

Write-Host "This script will create a set of PRTG SENSORS with counters based on the probe file <$probeSettingFile> and configurations files <$configFilter> in the folder:" -ForegroundColor White;
Write-Host "$configurationsPath" -ForegroundColor White;
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

# delete sensors confirmation
$adminPassword = ""
if ($deleteMatchingSensors)
{
    Write-Host "!!! WARNING !!! This setting should be changed only by an admin. Removing a sensor will delete all its related history! Are you sure? [Y/N]" -ForegroundColor Yellow
    $continue = Read-Host
    if ($continue -eq "Y")
    {
        Write-Host "Insert the admin password:" -ForegroundColor Yellow
        $adminPassword = Read-Host
        if ($adminPassword -ne $password)
        {
            Write-Host "Password incorrect! The existing sensors will not be deleted!" -ForegroundColor Red
            $deleteMatchingSensors = $false; 
        }
    }
    else
    {
        $deleteMatchingSensors = $false; 
    }
}

# device check
if ($deviceName -eq "")
{
    Write-Host "You must specify a device name. Please add it into the <$probeSettingFile> file." -ForegroundColor Red
    exit;
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

# checking for the device name (returning ps list object)
Write-Host "Reading device '$deviceName' ..." -ForegroundColor Gray;
$devices = Get-Device $DeviceName;
if ($devices.length -ne 1)
{
    Write-Host "Device '$device.Name' not found or there are more than a device with the filter condition! Quitting..." -ForegroundColor Red;
    Write-Host "Disconnecting..." -ForegroundColor Gray;
    Disconnect-PrtgServer;
    Write-Host "Disconnected!" -ForegroundColor White;
    exit;
}
$device = $devices | Select-Object -First 1;

# get the already installed sensors
Write-Host "Reading sensors for device '$deviceName' ..." -ForegroundColor Gray;
$installedSensors = Get-Device -Id $device.Id | Get-Sensor;

#loop on configuration files
Get-ChildItem $configurationsPath -Filter $configFilter | 
Foreach-Object {
    if ($_.FullName -eq $probeSettingFile)
    {
        continue;
    }
    Write-Host "-----------------------------------------------------------------" -ForegroundColor White
    Write-Host "Loading configuration from file: $_" -ForegroundColor Gray

    # reading configs (json file)
    $config = Get-Sensor-Config -ConfigFileName $_ -CurrentFolder $configurationsPath;
    $sensors = $config.Sensors;
    $isvalidjson = $config.IsValidJson;
    if ($isvalidjson -eq $false)
    {
        Write-Host "Invalid Id reference inside config file. Please check <$_> file." -ForegroundColor Red;
        Write-Host "Disconnecting..." -ForegroundColor Gray;
        Disconnect-PrtgServer;
        Write-Host "Disconnected!" -ForegroundColor White;
        exit;
    }

    # managing the sensors
    foreach ($sensor in $sensors)
    {
        $matchingSensors = $installedSensors | Where-Object { $_.Name -eq $sensor.name }
        if (!$matchingSensors)
        {
            # creating the sensor
            Write-Host "Creating "$sensor.name"..." -ForegroundColor Gray -NoNewline
            $params = $device | New-SensorParameters -RawType $sensor.type
            $params.Name = $sensor.name
            $params.Tags = $sensor.tags
            $params.Priority = $sensor.priority

            if ($sensor.InheritInterval -eq $true)
            {
                $params.InheritInterval = 1
            }
            else
            {
                $params.InheritInterval = 0
                $params.interval = $sensor.interval
            }

            #$params.primarychannel = $sensor.primary_channel

            if ($sensor.type -eq "pccustom")
            {
                $params.Counters = ""
                $encodedSettings = ""
                foreach ($channel in $sensor.channels)
                {
                    $encodedSettings += $channel.name +"::"+ $channel.measure_unit + "`n"
                }
                $encodedSettings = $encodedSettings.Substring(0, $encodedSettings.Length-1);
                $params.Counters = $encodedSettings
            }
		    elseif ($sensor.type -eq "mssqlv2")
		    {
		        $params.database = $sensor.database
                $params.useinstancename = $sensor.useinstancename
                if ($params.useinstancename -eq 1)
                {
                    $params.instancename = $sensor.instancename
                }
                $params.executionmode = "ReadData"
                $params.sqlquery = $sensor.sqlquery
                if ($sensor.enabled_channels -ge 1)
                {
                    $params.channel1name = $sensor.channel1_name
                    $params.channel1columnnumber = $sensor.channel1_columnnumber
                }
                if ($sensor.enabled_channels -ge 2)
                {
                    $params.usechannel2 = 1
                    $params.channel2name = $sensor.channel2_name
                    $params.channel2columnnumber = $sensor.channel2_columnnumber
                }
                if ($sensor.enabled_channels -ge 3)
                {
                    $params.usechannel3 = 1
                    $params.channel3name = $sensor.channel3_name
                    $params.channel3columnnumber = $sensor.channel3_columnnumber
                }
                if ($sensor.enabled_channels -ge 4)
                {
                    $params.usechannel4 = 1
                    $params.channel4name = $sensor.channel4_name
                    $params.channel4columnnumber = $sensor.channel4_columnnumber
                }
                if ($sensor.enabled_channels -ge 5)
                {
                    $params.usechannel5 = 1
                    $params.channel5name = $sensor.channel5_name
                    $params.channel5columnnumber = $sensor.channel5_columnnumber
                }
                if ($sensor.enabled_channels -ge 6)
                {
                    $params.usechannel6 = 1
                    $params.channel6name = $sensor.channel6_name
                    $params.channel6columnnumber = $sensor.channel6_columnnumber
                }
                if ($sensor.enabled_channels -ge 7)
                {
                    $params.usechannel7 = 1
                    $params.channel7name = $sensor.channel7_name
                    $params.channel7columnnumber = $sensor.channel7_columnnumber
                }
                if ($sensor.enabled_channels -ge 8)
                {
                    $params.usechannel8 = 1
                    $params.channel8name = $sensor.channel8_name
                    $params.channel8columnnumber = $sensor.channel8_columnnumber
                }
                if ($sensor.enabled_channels -ge 9)
                {
                    $params.usechannel9 = 1
                    $params.channel9name = $sensor.channel9_name
                    $params.channel9columnnumber = $sensor.channel9_columnnumber
                }
                if ($sensor.enabled_channels -ge 10)
                {
                    $params.usechannel10 = 1
                    $params.channel10name = $sensor.channel10_name
                    $params.channel10columnnumber = $sensor.channel10_columnnumber
                }
		    }
		    elseif ($sensor.type -eq "aggregation")
		    {
                $encodedSettings = ""
		        $params.aggregationchannel = $sensor.aggregation_channel
                foreach ($channel in $sensor.channels)
                {
                    $channelFunction = $channel.function
                    $InternalSIDMatches = ([Regex]::new("(?<={SID:)(.+?)(?=})")).Matches($channelFunction) 
                    foreach ($match in $InternalSIDMatches)
                    {
                        $sensorName = ($sensors | Where-Object { $_.internal_sensorId -eq $match.Value } | Select-Object -First 1 ).name
                        $retrivedSensorId = (Get-Device -Id $device.Id | Get-Sensor -Name $sensorName | Select-Object -First 1).id 
                        $channelFunction = $channelFunction -replace ("{SID:"+$match+"}"), [string]$retrivedSensorId
                    }

                    $encodedSettings += "#"+$channel.channelId+":"+$channel.name+"`n"+ $channelFunction + "`n"
                }
                $encodedSettings = $encodedSettings.Substring(0, $encodedSettings.Length-1);
                $params.aggregationchannel = $encodedSettings
		    }

            $createdSensor = Get-Device -Id $device.Id | Add-Sensor -Parameters $params
            #$params | Format-List
            Write-Host "Done!" -ForegroundColor White

            Write-Host "Refresh sensor..." -ForegroundColor Gray
            $createdSensor | Refresh-Object
            Write-Host "Sensor refreshed!" -ForegroundColor White

            # loop again the configuration for the thresholds
            foreach ($channel in $sensor.channels)
            {
                foreach ($property in $channel.properties)
                {
                    if ($channel.limit_type -ne "none") # skip if none (no thresholds)
                    {
                        $channelName = $channel.name.Substring($channel.name.LastIndexOf('\') + 1)
                        # I wait, otherwise the configuration of the properties fails
                        $waitingStep = 1
                        $maxWaitingStep = 50
                        $isChannelCreated = $CreatedSensor | Get-Channel -Name $channelName
                        while (($isChannelCreated -eq $null) -and ($waitingStep -le $maxWaitingStep))
                        {
                            Write-Progress -Activity "Waiting for channels creation..." -Status "$waitingStep";
                            #Write-Host "$waitingStep - Waiting for channels creation..."
                            Start-Sleep -Milliseconds 100
                            $waitingStep += 1
                            $isChannelCreated = $CreatedSensor | Get-Channel -Name $channelName
                        }
                        Write-Progress -Activity "Waiting for channels creation..." -Completed
                        if ($waitingStep -ge $maxWaitingStep)
                        {
                            Write-Host "Chaannels NOT created!" -ForegroundColor red
                        }
                        #if (($waitingStep -gt 1) -and ($waitingStep -lt $maxWaitingStep))
                        #{
                        #    Write-Host "Chaannels created!" -ForegroundColor White
                        #}

                        if ($channel.limit_type -eq "upper")
                        {
                            # upper limit
                            $CreatedSensor | Get-Channel -Name $channelName | Set-ChannelProperty -LimitsEnabled 1 -UpperErrorLimit $property.upper_error_limit -UpperWarningLimit $property.upper_warning_limit -ErrorLimitMessage $property.error_limit_message -WarningLimitMessage $property.warning_limit_message
                        } else # lower
                        {
                            # lower limit
                            $CreatedSensor | Get-Channel -Name $channelName | Set-ChannelProperty -LimitsEnabled 1 -LowerErrorLimit $property.lower_error_limit -LowerWarningLimit $property.lower_warning_limit -ErrorLimitMessage $property.error_limit_message -WarningLimitMessage $property.warning_limit_message
                        }
                    }
                }    
            }
        } else 
        {
            if ($deleteMatchingSensors)
            {
                foreach ($matchingSensor in $matchingSensors)
                {
                    Write-Host "Removing "$matchingSensor.name"..." -ForegroundColor Gray -NoNewline
                    $matchingSensor | Remove-Object -Force
                    Write-Host "Done!" -ForegroundColor White
                }
            }
        }
    }

}

Write-Host 
Write-Host "Disconnecting..." -ForegroundColor Gray;
Disconnect-PrtgServer;
Write-Host "Disconnected!" -ForegroundColor White;

