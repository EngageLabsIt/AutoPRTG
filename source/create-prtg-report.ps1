$currentFolder = Split-Path $MyInvocation.MyCommand.Definition -Parent
. "$currentFolder\functions.ps1"

######ignore invalid SSL Certs##########
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

Clear-Host;
$error.Clear();

$configurationsFolder = "Configurations";
$probeSettingFile = "probe-settings.json";
$configFilter = "config*.json";

$configurationsPath = Join-Path -Path $CurrentFolder -ChildPath $configurationsFolder;

Write-Host "This script will create a set of PRTG REPORTS with counters based on the probe file <$probeSettingFile> and configurations files <$configFilter> in the folder:" -ForegroundColor White;
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

if ($PRTGHost.Substring(0, 4) -ne "http")
{
    $PRTGUrl = "https:\\$PRTGHost"
}
else
{
    $PRTGUrl = $PRTGHost
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
    $config = Get-Sensor-Config -ConfigFileName $_ -CurrentFolder $configurationsPath
    $sensors = $config.Sensors
    $reports = $config.Reports
    $isvalidjson = $config.IsValidJson
    if ($isvalidjson -eq $false)
    {
        Write-Host "Invalid Id reference inside config file. Please check <$_> file." -ForegroundColor Red;
        Write-Host "Disconnecting..." -ForegroundColor Gray;
        Disconnect-PrtgServer;
        Write-Host "Disconnected!" -ForegroundColor White;
        exit;
    }
    
    #region parameters
    #region template
    #$template="A30 Graph with Data Table - Graph 1m - Table 1m.htm"
    #$template="A31 Graph with Data Table - Graph 5m - Table 5m.htm"
    #$template="A32 Graph with Data Table - Graph 15m - Table 15m.htm"
    #$template="A33 Graph with Data Table - Graph 30m - Table 30m.htm"
    #$template="A41 Graph with Data Table - Graph 1h - Table 1h.htm"
    #$template="A42 Graph with Data Table - Graph 1h - Table 24h.htm"
    #$template="A50 Graph with Data Table - Graph 24h - Table 24h.htm"
    #$template="A60 Data Table - Table 1m.htm"
    #$template="A61 Data Table - Table 5m.htm"
    #$template="A62 Data Table - Table 15m.htm"
    #$template="A63 Data Table - Table 30m.htm"
    #$template="A64 Data Table - Table 1h.htm"
    #$template="A65 Data Table - Table 24h.htm"
    $template="B01 Graph Only - 1m.htm"
    #$template="B02 Graph Only - 5m.htm"
    #$template="B03 Graph Only - 15m.htm"
    #$template="B04 Graph Only - 30m.htm"
    #$template="B05 Graph Only - 60m.htm"
    #$template="B11 Graph Only - 24h.htm"
    #$template="C01 Sensorlist 60m.htm"
    #$template="C02 Sensorlist nograph.htm"
    #$template="T1a Top100 Highest and Lowest (1min).htm"
    #$template="T1b Top100 Highest and Lowest (5min).htm"
    #$template="T1c Top100 Highest and Lowest (60min).htm"
    #$template="T2 Top10 Uptime percent.htm"
    #$template="T2 Top10 Uptime time.htm"
    #$template="T3 Top100 Uptime percent.htm"
    #$template="T3 Top100 Uptime time.htm"
    #endregion template

    #region timezone
    #$timezone="Dateline Standard Time|(UTC-12:00) International Date Line West"
    #$timezone="UTC-11|(UTC-11:00) Coordinated Universal Time-11"
    #$timezone="Hawaiian Standard Time|(UTC-10:00) Hawaii"
    #$timezone="Aleutian Standard Time|(UTC-10:00) Aleutian Islands"
    #$timezone="Marquesas Standard Time|(UTC-09:30) Marquesas Islands"
    #$timezone="UTC-09|(UTC-09:00) Coordinated Universal Time-09"
    #$timezone="Alaskan Standard Time|(UTC-09:00) Alaska"
    #$timezone="Pacific Standard Time (Mexico)|(UTC-08:00) Baja California"
    #$timezone="UTC-08|(UTC-08:00) Coordinated Universal Time-08"
    #$timezone="Pacific Standard Time|(UTC-08:00) Pacific Time (US &amp; Canada)"
    #$timezone="Mountain Standard Time (Mexico)|(UTC-07:00) Chihuahua, La Paz, Mazatlan"
    #$timezone="US Mountain Standard Time|(UTC-07:00) Arizona"
    #$timezone="Mountain Standard Time|(UTC-07:00) Mountain Time (US &amp; Canada)"
    #$timezone="Central America Standard Time|(UTC-06:00) Central America"
    #$timezone="Canada Central Standard Time|(UTC-06:00) Saskatchewan"
    #$timezone="Central Standard Time|(UTC-06:00) Central Time (US &amp; Canada)"
    #$timezone="Easter Island Standard Time|(UTC-06:00) Easter Island"
    #$timezone="Central Standard Time (Mexico)|(UTC-06:00) Guadalajara, Mexico City, Monterrey"
    #$timezone="Haiti Standard Time|(UTC-05:00) Haiti"
    #$timezone="US Eastern Standard Time|(UTC-05:00) Indiana (East)"
    #$timezone="SA Pacific Standard Time|(UTC-05:00) Bogota, Lima, Quito, Rio Branco"
    #$timezone="Cuba Standard Time|(UTC-05:00) Havana"
    #$timezone="Eastern Standard Time (Mexico)|(UTC-05:00) Chetumal"
    #$timezone="Turks And Caicos Standard Time|(UTC-05:00) Turks and Caicos"
    #$timezone="Eastern Standard Time|(UTC-05:00) Eastern Time (US &amp; Canada)"
    #$timezone="Pacific SA Standard Time|(UTC-04:00) Santiago"
    #$timezone="SA Western Standard Time|(UTC-04:00) Georgetown, La Paz, Manaus, San Juan"
    #$timezone="Atlantic Standard Time|(UTC-04:00) Atlantic Time (Canada)"
    #$timezone="Venezuela Standard Time|(UTC-04:00) Caracas"
    #$timezone="Paraguay Standard Time|(UTC-04:00) Asuncion"
    #$timezone="Central Brazilian Standard Time|(UTC-04:00) Cuiaba"
    #$timezone="Newfoundland Standard Time|(UTC-03:30) Newfoundland"
    #$timezone="E. South America Standard Time|(UTC-03:00) Brasilia"
    #$timezone="SA Eastern Standard Time|(UTC-03:00) Cayenne, Fortaleza"
    #$timezone="Argentina Standard Time|(UTC-03:00) City of Buenos Aires"
    #$timezone="Montevideo Standard Time|(UTC-03:00) Montevideo"
    #$timezone="Magallanes Standard Time|(UTC-03:00) Punta Arenas"
    #$timezone="Tocantins Standard Time|(UTC-03:00) Araguaina"
    #$timezone="Bahia Standard Time|(UTC-03:00) Salvador"
    #$timezone="Saint Pierre Standard Time|(UTC-03:00) Saint Pierre and Miquelon"
    #$timezone="Greenland Standard Time|(UTC-03:00) Greenland"
    #$timezone="Mid-Atlantic Standard Time|(UTC-02:00) Mid-Atlantic - Old"
    #$timezone="UTC-02|(UTC-02:00) Coordinated Universal Time-02"
    #$timezone="Azores Standard Time|(UTC-01:00) Azores"
    #$timezone="Cape Verde Standard Time|(UTC-01:00) Cabo Verde Is."
    #$timezone="GMT Standard Time|(UTC+00:00) Dublin, Edinburgh, Lisbon, London"
    #$timezone="Greenwich Standard Time|(UTC+00:00) Monrovia, Reykjavik"
    #$timezone="UTC|(UTC) Coordinated Universal Time"
    #$timezone="Morocco Standard Time|(UTC+00:00) Casablanca"
    #$timezone="W. Central Africa Standard Time|(UTC+01:00) West Central Africa"
    $timezone="W. Europe Standard Time|(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"
    #$timezone="Central Europe Standard Time|(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague"
    #$timezone="Central European Standard Time|(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb"
    #$timezone="Sao Tome Standard Time|(UTC+01:00) Sao Tome"
    #$timezone="Romance Standard Time|(UTC+01:00) Brussels, Copenhagen, Madrid, Paris"
    #$timezone="Syria Standard Time|(UTC+02:00) Damascus"
    #$timezone="West Bank Standard Time|(UTC+02:00) Gaza, Hebron"
    #$timezone="Middle East Standard Time|(UTC+02:00) Beirut"
    #$timezone="South Africa Standard Time|(UTC+02:00) Harare, Pretoria"
    #$timezone="Namibia Standard Time|(UTC+02:00) Windhoek"
    #$timezone="Sudan Standard Time|(UTC+02:00) Khartoum"
    #$timezone="Israel Standard Time|(UTC+02:00) Jerusalem"
    #$timezone="E. Europe Standard Time|(UTC+02:00) Chisinau"
    #$timezone="Kaliningrad Standard Time|(UTC+02:00) Kaliningrad"
    #$timezone="Jordan Standard Time|(UTC+02:00) Amman"
    #$timezone="FLE Standard Time|(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius"
    #$timezone="GTB Standard Time|(UTC+02:00) Athens, Bucharest"
    #$timezone="Libya Standard Time|(UTC+02:00) Tripoli"
    #$timezone="Egypt Standard Time|(UTC+02:00) Cairo"
    #$timezone="Arabic Standard Time|(UTC+03:00) Baghdad"
    #$timezone="Turkey Standard Time|(UTC+03:00) Istanbul"
    #$timezone="Belarus Standard Time|(UTC+03:00) Minsk"
    #$timezone="Arab Standard Time|(UTC+03:00) Kuwait, Riyadh"
    #$timezone="Russian Standard Time|(UTC+03:00) Moscow, St. Petersburg, Volgograd"
    #$timezone="E. Africa Standard Time|(UTC+03:00) Nairobi"
    #$timezone="Iran Standard Time|(UTC+03:30) Tehran"
    #$timezone="Azerbaijan Standard Time|(UTC+04:00) Baku"
    #$timezone="Mauritius Standard Time|(UTC+04:00) Port Louis"
    #$timezone="Russia Time Zone 3|(UTC+04:00) Izhevsk, Samara"
    #$timezone="Saratov Standard Time|(UTC+04:00) Saratov"
    #$timezone="Caucasus Standard Time|(UTC+04:00) Yerevan"
    #$timezone="Arabian Standard Time|(UTC+04:00) Abu Dhabi, Muscat"
    #$timezone="Astrakhan Standard Time|(UTC+04:00) Astrakhan, Ulyanovsk"
    #$timezone="Georgian Standard Time|(UTC+04:00) Tbilisi"
    #$timezone="Afghanistan Standard Time|(UTC+04:30) Kabul"
    #$timezone="Pakistan Standard Time|(UTC+05:00) Islamabad, Karachi"
    #$timezone="Ekaterinburg Standard Time|(UTC+05:00) Ekaterinburg"
    #$timezone="West Asia Standard Time|(UTC+05:00) Ashgabat, Tashkent"
    #$timezone="Sri Lanka Standard Time|(UTC+05:30) Sri Jayawardenepura"
    #$timezone="India Standard Time|(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi"
    #$timezone="Nepal Standard Time|(UTC+05:45) Kathmandu"
    #$timezone="Omsk Standard Time|(UTC+06:00) Omsk"
    #$timezone="Bangladesh Standard Time|(UTC+06:00) Dhaka"
    #$timezone="Central Asia Standard Time|(UTC+06:00) Astana"
    #$timezone="Myanmar Standard Time|(UTC+06:30) Yangon (Rangoon)"
    #$timezone="SE Asia Standard Time|(UTC+07:00) Bangkok, Hanoi, Jakarta"
    #$timezone="W. Mongolia Standard Time|(UTC+07:00) Hovd"
    #$timezone="Tomsk Standard Time|(UTC+07:00) Tomsk"
    #$timezone="Altai Standard Time|(UTC+07:00) Barnaul, Gorno-Altaysk"
    #$timezone="North Asia Standard Time|(UTC+07:00) Krasnoyarsk"
    #$timezone="N. Central Asia Standard Time|(UTC+07:00) Novosibirsk"
    #$timezone="Taipei Standard Time|(UTC+08:00) Taipei"
    #$timezone="Ulaanbaatar Standard Time|(UTC+08:00) Ulaanbaatar"
    #$timezone="Singapore Standard Time|(UTC+08:00) Kuala Lumpur, Singapore"
    #$timezone="North Asia East Standard Time|(UTC+08:00) Irkutsk"
    #$timezone="W. Australia Standard Time|(UTC+08:00) Perth"
    #$timezone="China Standard Time|(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi"
    #$timezone="North Korea Standard Time|(UTC+08:30) Pyongyang"
    #$timezone="Aus Central W. Standard Time|(UTC+08:45) Eucla"
    #$timezone="Transbaikal Standard Time|(UTC+09:00) Chita"
    #$timezone="Yakutsk Standard Time|(UTC+09:00) Yakutsk"
    #$timezone="Tokyo Standard Time|(UTC+09:00) Osaka, Sapporo, Tokyo"
    #$timezone="Korea Standard Time|(UTC+09:00) Seoul"
    #$timezone="Cen. Australia Standard Time|(UTC+09:30) Adelaide"
    #$timezone="AUS Central Standard Time|(UTC+09:30) Darwin"
    #$timezone="AUS Eastern Standard Time|(UTC+10:00) Canberra, Melbourne, Sydney"
    #$timezone="Vladivostok Standard Time|(UTC+10:00) Vladivostok"
    #$timezone="E. Australia Standard Time|(UTC+10:00) Brisbane"
    #$timezone="West Pacific Standard Time|(UTC+10:00) Guam, Port Moresby"
    #$timezone="Tasmania Standard Time|(UTC+10:00) Hobart"
    #$timezone="Lord Howe Standard Time|(UTC+10:30) Lord Howe Island"
    #$timezone="Central Pacific Standard Time|(UTC+11:00) Solomon Is., New Caledonia"
    #$timezone="Sakhalin Standard Time|(UTC+11:00) Sakhalin"
    #$timezone="Norfolk Standard Time|(UTC+11:00) Norfolk Island"
    #$timezone="Bougainville Standard Time|(UTC+11:00) Bougainville Island"
    #$timezone="Magadan Standard Time|(UTC+11:00) Magadan"
    #$timezone="Russia Time Zone 10|(UTC+11:00) Chokurdakh"
    #$timezone="Fiji Standard Time|(UTC+12:00) Fiji"
    #$timezone="Russia Time Zone 11|(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky"
    #$timezone="UTC+12|(UTC+12:00) Coordinated Universal Time+12"
    #$timezone="Kamchatka Standard Time|(UTC+12:00) Petropavlovsk-Kamchatsky - Old"
    #$timezone="New Zealand Standard Time|(UTC+12:00) Auckland, Wellington"
    #$timezone="Chatham Islands Standard Time|(UTC+12:45) Chatham Islands"
    #$timezone="UTC+13|(UTC+13:00) Coordinated Universal Time+13"
    #$timezone="Tonga Standard Time|(UTC+13:00) Nuku'alofa"
    #$timezone="Samoa Standard Time|(UTC+13:00) Samoa"
    #$timezone="Line Islands Standard Time|(UTC+14:00) Kiritimati Island"
    #endregion timezone

    #region papersize
    #$papersize="none"
    #$papersize="a4"
    #$papersize="a3"
    #$papersize="a2"
    #$papersize="legal"
    $papersize="letter"
    #$papersize="ledger"
    #endregion papersize

    $orientation="0" #Portrait
    #$orientation="1" #Landscape

    #$scheduletype="0" #No schedule (run interactively/on-demand only)
    #$scheduletype="1" #Every full hour
    #$scheduletype="2" #Every day at a specific hour
    #$scheduletype="3" #Every specific day of a week
    #$scheduletype="4" #Every specific day of a month
    $scheduletype="6" #The day after a quarter has finished
    #$scheduletype="5" #Every specific date. Set also: &specifichour_=0&dayweek_=1&daymonth_=1&date_=

    #$specifichour="0"
    #$dayweek="1"
    #$daymonth="1"
    #$date=""

    $maildisk="0" #Save report to disk and send it by email
    #$maildisk="1" #Save report to disk only
    #$maildisk="2" #Send report by email only

    $usecompression="0" #Send files uncompressed (default)
    #$usecompression="1" #Send all in one ZIP file

    #$dataperiod="0" #Current
    $dataperiod="1" #Previous

    #$reporttype="0" #Day
    #$reporttype="1" #Week
    #$reporttype="2" #Month
    $reporttype="4" #Quarter (January-March, April-June, etc.)
    #$reporttype="3" #Year

    $accessrights_group="1111" #id grup of PRTG.Baselines
    #$accessrights_value="0"   #None
    $accessrights_value="100" #Read
    #$accessrights_value="200" #Write
    #$accessrights_value="400" #Full

    #endregion parameters

    # managing the sensors
    foreach ($report in $reports)
    {
        $ReportName = $report.name
        $template = $report.template

        #Get Id from owner
        $ownerProp = Get-Object -Name $report.owner;
        if ($ownerProp -eq $null)
        {
            Write-Host "Current user doesn't have the privileges to see user accounts!" -ForegroundColor Red;
            Write-Host "Disconnecting..." -ForegroundColor Gray;
            Disconnect-PrtgServer;
            Write-Host "Disconnected!" -ForegroundColor White;
            exit;
        }
        $ownerId = $ownerProp.Id;
        $ownerName = $ownerProp.Name;

        $timezone = $report.timezone
        $papersize = $report.papersize
        $orientation = $report.orientation
        $scheduletype = $report.scheduletype
        $maildisk = $report.maildisk
        $emailaddress = $report.emailaddress
        $emailgroup = $report.emailgroup
        $usecompression = $report.usecompression
        $dataperiod = $report.dataperiod
        $reporttype = $report.reporttype
        #Get Id from accessrights_group
        $groupProp = Get-Object -Name $report.accessrights_group
        if ($groupProp -eq $null)
        {
            Write-Host "Current user doesn't have the privileges to see user groups!" -ForegroundColor Red;
            Write-Host "Disconnecting..." -ForegroundColor Gray;
            Disconnect-PrtgServer;
            Write-Host "Disconnected!" -ForegroundColor White;
            exit;
        }
        $accessrights_group = $groupProp.Id
        $accessrights_value = $report.accessrights_value

        $request  = "$PRTGUrl/editsettings?"
        $request += "name_=$ReportName"
        $request += "&tags_=&template_=$template"
        $request += "&ownerid_=$ownerId|$ownerName|"
        $request += "&timezone_=$timezone"
        $request += "&papersize_=$papersize"
        $request += "&orientation_=$orientation"
        $request += "&comments=&tagfilter_=&filtertag_="
        $request += "&scheduletype_=$scheduletype&specifichour_=0&dayweek_=1&daymonth_=1&date_="
        $request += "&maildisk_=$maildisk&emailaddress_=$emailaddress&emailgroup_=$emailgroup&usecompression_=$usecompression"
        $request += "&dataperiod_=$dataperiod&reporttype_=$reporttype&reportday_=0&reportweek_=1&reportmonth_=1&reportyear_=1&schedule_=-1%7CNone%7C"
        $request += "&percentileshow_=0&percentile_=95&percentileaverage_=300&percentilemode_=1"
        $request += "&savedatafiles_=nofiles"
        $request += "&reportheader_=&reportfooter_="
        $request += "&accessrights_=1&accessrights_$accessrights_group=$accessrights_value"
        $request += "&objecttype=report&id=new&addid=&targeturl=%2Freport.htm%3Ftabid%3D4"
        $request += "&username=$username&password=$password"

        Write-Host "Creating report '$ReportName' ..." -ForegroundColor Gray
        $redirect = invoke-webrequest $request -MaximumRedirection 0 -ErrorAction SilentlyContinue

        # Extract the ID of the new report
        $redirectUrl = $redirect.Headers.Location
        $reportId = $redirectUrl -replace ".+id=(.+)",'$1'

        Write-Host "Created report $reportId" -ForegroundColor White
        Write-Host

        $ReportNodeId = 0  #Starting value - 1 (after the repoort creation set the value to 0)
        $auth = "&username=$username&password=$password"

        foreach ($reportSensor in $report.sensors)
        {
            $sensorName = ($sensors | Where { $_.internal_sensorId -eq $reportSensor.internal_sensorId } | Select-Object -First 1 ).name
            # checking for the sensor name (returning ps list object)
            $retrivedSensors = Get-Device -Id $device.Id | Get-Sensor -Name $sensorName
            if ($retrivedSensors.length -ne 1)
            {
                Write-Host "Sensor '$sensorName' not found or there are more than a sensor with the filter condition!" -ForegroundColor Red
            }
            else
            {
                $retrivedSensor = $retrivedSensors | Select-Object -First 1

                $reportNodeId++;

                [string[]]$channelNames = @()
                foreach ($channel in $reportSensor.channels)
                {
                    $channelName = (($sensors | Where { $_.internal_sensorId -eq $reportSensor.internal_sensorId } | Select-Object -First 1 ).channels | Where { $_.channelId -eq $channel.channelId} | Select-Object -First 1).name;
                    $channelName = $channelName.Substring($channelName.LastIndexOf('\') + 1);
                    $channelNames += ,$channelName;
                }
                Write-Host "Adding sensor '$sensorName' with channels: '$channelNames'..." -ForegroundColor Gray
                Add-prtgSensorToReport -PRTGHost $PRTGUrl -Auth $auth -ReportID $reportId -ReportNodeId $reportNodeId -SensorID $retrivedSensor.Id -ChannelNames $channelNames
                Write-Host "Added Sensor '$sensorName'" -ForegroundColor White
            }
            Write-Host;
        }
    }
}

Write-Host;
Write-Host "Disconnecting..." -ForegroundColor Gray;
Disconnect-PrtgServer;
Write-Host "Disconnected!" -ForegroundColor White;
