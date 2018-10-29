function pause (
    [string]$Message = $(Throw 'Message is required'))
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Write-Host $Message -ForegroundColor White
        $x = ""
    }
    else
    {
        Write-Host $Message -ForegroundColor White
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    return $x
}

function Get-Sensor-Config (
    [string]$ConfigFileName = $(Throw 'ConfigFileName is required'),
    [string]$CurrentFolder = $(Throw 'CurrentFolder is required')
)
{
    $extensionFile = Join-Path -Path $CurrentFolder -ChildPath $ConfigFileName
    $jsondata = Get-Content -Raw -Path $ExtensionFile | ConvertFrom-Json

    # check unique ids
	$isvalidjson = $true
	$sensorChannels = @{}
    foreach ($sens in $jsondata.sensors)
	{
		if (-not $sensorChannels.ContainsKey($sens.internal_sensorId))
		{
			$channels = New-Object 'System.Collections.Generic.List[Int]'
			foreach($channel in $sens.channels)
			{
				if ( (-not $channel.Count -eq 0) -and $channels -contains ($channel.channelId))
				{
					$isvalidjson = $false
				}
				else
				{
					$channels.Add($channel.channelId)
				}
			}
			$sensorChannels.Add($sens.internal_sensorId, $channels)
		}
		else
		{
			$isvalidjson = $false
		}
	}
    if ($isvalidjson -eq $true)
    {
	    foreach ($rep in $jsondata.reports)
	    {
		    foreach ($sens in $rep.sensors)
		    {
			    if ($sensorChannels.ContainsKey($sens.internal_sensorId))
			    {
				    foreach ($chan in $sens.channels)
				    {
					    if ( -not ($sensorChannels[$sens.internal_sensorId].Contains($chan.channelId)))
					    {
						    $isvalidjson = $false
					    }
				    }
			    }
                else
                {
                    $isvalidjson = $false
                }
		    }
	    }
    }

    New-Object psobject -property @{IsValidJson = $isvalidjson; PrtgHttpHost = $jsondata.prtg_http_host; PrtgUsername = $jsondata.prtg_username; PrtgPassword = $jsondata.prtg_password; DeviceName = $jsondata.device_name; Sensors = $jsondata.sensors; Reports = $jsondata.reports }
}

function Get-prtgSensorChannelIdsExcludedNames ([string]$SensorID, [string[]] $ChannelNames)
{
    #this does not retuen the channelID - rather important for somethings.
    $url = "$PRTGHost/api/table.xml?content=channels&output=csvtable&columns=objid,name&id=$SensorID&$auth"
    $request = Invoke-WebRequest -Uri $url -MaximumRedirection 0 -ErrorAction Ignore
    $Channels = convertFrom-csv ($request) -WarningAction SilentlyContinue
    $Channels | Where-Object { $_.Channel -notin $ChannelNames} | select ID
    
}

function Add-prtgSensorToReport
{
    [CmdletBinding()]
    
    param(
            [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$false)]
            [string]$PRTGHost,

            [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$false)]
            [string]$Auth,

            [Parameter(Mandatory=$False)]
            [int]$reportId,

            [Parameter(Mandatory=$False)]
            [int]$ReportNodeId,

            [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$false)]
            [int]$SensorID,

            [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$false)]
            [string[]]$ChannelNames
          )

    process
    {
        # Add sensor
        $url = "$PRTGHost/api/reportaddsensor.htm?id=$reportId&addid=$SensorID&$Auth"
        $request = Invoke-WebRequest -Uri $url -MaximumRedirection 0 -ErrorAction Ignore
    
        #Get Report sensor Id (node) better to evaluate the report node id HERE not given by outside
        #$ReportNodeId++

        #Delete unused channel
        $ChannelsToDelete = Get-prtgSensorChannelIdsExcludedNames -SensorID $SensorID -ChannelNames $ChannelNames
        foreach($ChannelToDelete in $ChannelsToDelete)
        {
            $ID = $ChannelToDelete.ID
            $url = "$PRTGHost/api/reportdeletesensorchannel.htm?id=$reportId&repnodeid=$ReportNodeId&channelid=$ID&$Auth"
            $request = Invoke-WebRequest -Uri $url -MaximumRedirection 0 -ErrorAction Ignore
        }
    }
}