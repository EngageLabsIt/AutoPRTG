# AutoPRTG

AutoPRTG is a solution based on a set of PowerShell script which allows us to create PRTG sensors and reports automatically. [PRTG](https://www.paessler.com/prtg) is a monitoring tool by [Paessler](https://www.paessler.com) and lets system administrators to monitor many environments at a glance. With sensors (sets of counters) you can view the status of servers, check their health and setup notifications. Unfortunately, creating new sensors manually is a challenging task. Indeed, each sensor needs many clicks, many configurations and, once created some kind of them cannot be edited. Wit AutoPRTG you can create JSON configuration files one shot and just execute the script using them. The complex task is moved to the JSON files configuration and you can run the script as you need (also dropping existing sensors if needed). You can make your templates, too, in order to avoid any manual re-creation of the PRTG items.
You can configure also the thresholds for notifications, the target of them and also the scheduled reports that you can check later.

AutoPRTG is based on [PRTG API](https://github.com/lordmilko/PrtgAPI) solution made by [Lord Milko](https://github.com/lordmilko).

## Advantages

- Quick create sensors
- Store the sensors configuration on JSON files
- Version the configurations on your own Source Control Manager
- Replicate the configurations for similar environments with minimal effort

## Usage

1. [Set the "Probe" options](#Set-the-Probe-options)
2. [Configure the JSON files for each set of sensors](#Configure-the-JSON-files)
3. Install the solution with `.bat` file. It will install automatically the PRTG API, too.

### Set the Probe options

The so-called Probe is the server that monitors and keeps track of one or more environment. It stores also the current configuration of PRTG and its sensors. The Probe settings file contains the connection information of PRTG. To configure it, modify the file `probe-settings.json`:

- **prtg_http_host**: contains the PRTG host name (with port number).

    > Example `monitoring.mycompany.com:23456`

- **prtg_username**: username used for accessing to PRTG portal. The user must have the privileges to see user accounts and user groups in order to assign reports to another user and user groups (see the [Reports section](#Reports-option)).
- **prtg_password**: user password
- **device_name**: target device where the sensors and/or report will be created

### Configure the JSON files

The configuration files are stored in the folder `configuration`. The file name must start with `config` and its extension must be `.json` as well as the syntax. These files contain the list of sensors and the list of reports that you would like to create.

If you need to make a report, you must add the sensors configurations, too. The reason is that the report will refer to them, using internal ids.

The configuration samples in this github project are ready to use while the report's one must be changed, depending on your personal PRTG data. In particular, you've to change:

- **owner**
- **emailaddress**
- **accessrights_group**

#### Sensors configuration option

- **internal_sensorId**: is the ID used in report configuration to link the sensor name
- **name**: sensor name
- **type**: sensor type. Following, the list of the supported type:
  - **pccustom**: “PerfCounter Custom”: Monitor a configured set of Performance Counters
  - **mssqlv2**: “Microsoft SQL v2”: Monitor a database on a Microsoft SQL Server (MSSQL)
  - **aggregation**: Aggregation channel based on other sensors.

- **tags**: list of sensors tag. You can use tags to group sensors and use tag–filtered views later on. Tags are case insensitive.
- **priority**: sensor priority. This setting determines where the sensor is placed in sensor lists. Top priority is at the top of a list. Choose from one (low priority) to five (top priority).
- **InheritInterval**: 1 = inerhit scanning interval
- **interval**: Scanning interval: The scanning interval determines the time the sensor waits between two scans.
- **primary_channel**: Primary Channel Id.
- **channels**: list of channels.

#### Channel configuration option

- **channelId**: Id of the channel. Start to set the configuration from ID number 2. Some of the first identifiers are used by the system.
- **name**: Channel Name
- **measure_unit**: Channel unit of measurement
- **limit_type**: limit type. Use 
  - **upper**: to set an upper limit
  - “lower**: to set a lower limit
  - **none**: to not set the limit
- **properties**: list of channel limit property.

#### Channel limit property configuration option

To set a limit you have to set an upper limit or lower limit, it is not possible set both limits.

- **upper_error_limit**: Upper error limit
- **upper_warning_limit**: Upper warning limit
- **lower_error_limit**: Lower error limit
- **lower_warning_limit**: Lower warning limit
- **error_limit_message**: Error limit message
- **warning_limit_message**: Warning limit message

#### Reports option

- **name**: Report name
- **template**: Name of the template that this report uses. You have to use one of those templates:
  - "A30 Graph with Data Table - Graph 1m - Table 1m.htm"
  - "A31 Graph with Data Table - Graph 5m - Table 5m.htm"
  - "A32 Graph with Data Table - Graph 15m - Table 15m.htm"
  - "A33 Graph with Data Table - Graph 30m - Table 30m.htm"
  - "A41 Graph with Data Table - Graph 1h - Table 1h.htm"
  - "A42 Graph with Data Table - Graph 1h - Table 24h.htm"
  - "A50 Graph with Data Table - Graph 24h - Table 24h.htm"
  - "A60 Data Table - Table 1m.htm"
  - "A61 Data Table - Table 5m.htm"
  - "A62 Data Table - Table 15m.htm"
  - "A63 Data Table - Table 30m.htm"
  - "A64 Data Table - Table 1h.htm"
  - "A65 Data Table - Table 24h.htm"
  - "B01 Graph Only - 1m.htm"
  - "B02 Graph Only - 5m.htm"
  - "B03 Graph Only - 15m.htm"
  - "B04 Graph Only - 30m.htm"
  - "B05 Graph Only - 60m.htm"
  - "B11 Graph Only - 24h.htm"
  - "C01 Sensorlist 60m.htm"
  - "C02 Sensorlist nograph.htm"
  - "T1a Top100 Highest and Lowest (1min).htm"
  - "T1b Top100 Highest and Lowest (5min).htm"
  - "T1c Top100 Highest and Lowest (60min).htm"
  - "T2 Top10 Uptime percent.htm"
  - "T2 Top10 Uptime time.htm"
  - "T3 Top100 Uptime percent.htm"
  - "T3 Top100 Uptime time.htm"

- **owner**: PRTG user account that PRTG uses to run the report. This user must have the grant to see the sensors.
- **timezone**: timezone for all dates in this report. This includes schedule dates, report time span, and dates in tables and graphs. You have to use one of those value:
  - "Dateline Standard Time|(UTC-12:00) International Date Line West"
  - "UTC-11|(UTC-11:00) Coordinated Universal Time-11"
  - "Hawaiian Standard Time|(UTC-10:00) Hawaii"
  - "Aleutian Standard Time|(UTC-10:00) Aleutian Islands"
  - "Marquesas Standard Time|(UTC-09:30) Marquesas Islands"
  - "UTC-09|(UTC-09:00) Coordinated Universal Time-09"
  - "Alaskan Standard Time|(UTC-09:00) Alaska"
  - "Pacific Standard Time (Mexico)|(UTC-08:00) Baja California"
  - "UTC-08|(UTC-08:00) Coordinated Universal Time-08"
  - "Pacific Standard Time|(UTC-08:00) Pacific Time (US &amp; Canada)"
  - "Mountain Standard Time (Mexico)|(UTC-07:00) Chihuahua, La Paz, Mazatlan"
  - "US Mountain Standard Time|(UTC-07:00) Arizona"
  - "Mountain Standard Time|(UTC-07:00) Mountain Time (US &amp; Canada)"
  - "Central America Standard Time|(UTC-06:00) Central America"
  - "Canada Central Standard Time|(UTC-06:00) Saskatchewan"
  - "Central Standard Time|(UTC-06:00) Central Time (US &amp; Canada)"
  - "Easter Island Standard Time|(UTC-06:00) Easter Island"
  - "Central Standard Time (Mexico)|(UTC-06:00) Guadalajara, Mexico City, Monterrey"
  - "Haiti Standard Time|(UTC-05:00) Haiti"
  - "US Eastern Standard Time|(UTC-05:00) Indiana (East)"
  - "SA Pacific Standard Time|(UTC-05:00) Bogota, Lima, Quito, Rio Branco"
  - "Cuba Standard Time|(UTC-05:00) Havana"
  - "Eastern Standard Time (Mexico)|(UTC-05:00) Chetumal"
  - "Turks And Caicos Standard Time|(UTC-05:00) Turks and Caicos"
  - "Eastern Standard Time|(UTC-05:00) Eastern Time (US &amp; Canada)"
  - "Pacific SA Standard Time|(UTC-04:00) Santiago"
  - "SA Western Standard Time|(UTC-04:00) Georgetown, La Paz, Manaus, San Juan"
  - "Atlantic Standard Time|(UTC-04:00) Atlantic Time (Canada)"
  - "Venezuela Standard Time|(UTC-04:00) Caracas"
  - "Paraguay Standard Time|(UTC-04:00) Asuncion"
  - "Central Brazilian Standard Time|(UTC-04:00) Cuiaba"
  - "Newfoundland Standard Time|(UTC-03:30) Newfoundland"
  - "E. South America Standard Time|(UTC-03:00) Brasilia"
  - "SA Eastern Standard Time|(UTC-03:00) Cayenne, Fortaleza"
  - "Argentina Standard Time|(UTC-03:00) City of Buenos Aires"
  - "Montevideo Standard Time|(UTC-03:00) Montevideo"
  - "Magallanes Standard Time|(UTC-03:00) Punta Arenas"
  - "Tocantins Standard Time|(UTC-03:00) Araguaina"
  - "Bahia Standard Time|(UTC-03:00) Salvador"
  - "Saint Pierre Standard Time|(UTC-03:00) Saint Pierre and Miquelon"
  - "Greenland Standard Time|(UTC-03:00) Greenland"
  - "Mid-Atlantic Standard Time|(UTC-02:00) Mid-Atlantic - Old"
  - "UTC-02|(UTC-02:00) Coordinated Universal Time-02"
  - "Azores Standard Time|(UTC-01:00) Azores"
  - "Cape Verde Standard Time|(UTC-01:00) Cabo Verde Is."
  - "GMT Standard Time|(UTC+00:00) Dublin, Edinburgh, Lisbon, London"
  - "Greenwich Standard Time|(UTC+00:00) Monrovia, Reykjavik"
  - "UTC|(UTC) Coordinated Universal Time"
  - "Morocco Standard Time|(UTC+00:00) Casablanca"
  - "W. Central Africa Standard Time|(UTC+01:00) West Central Africa"
  - "W. Europe Standard Time|(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"
  - "Central Europe Standard Time|(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague"
  - "Central European Standard Time|(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb"
  - "Sao Tome Standard Time|(UTC+01:00) Sao Tome"
  - "Romance Standard Time|(UTC+01:00) Brussels, Copenhagen, Madrid, Paris"
  - "Syria Standard Time|(UTC+02:00) Damascus"
  - "West Bank Standard Time|(UTC+02:00) Gaza, Hebron"
  - "Middle East Standard Time|(UTC+02:00) Beirut"
  - "South Africa Standard Time|(UTC+02:00) Harare, Pretoria"
  - "Namibia Standard Time|(UTC+02:00) Windhoek"
  - "Sudan Standard Time|(UTC+02:00) Khartoum"
  - "Israel Standard Time|(UTC+02:00) Jerusalem"
  - "E. Europe Standard Time|(UTC+02:00) Chisinau"
  - "Kaliningrad Standard Time|(UTC+02:00) Kaliningrad"
  - "Jordan Standard Time|(UTC+02:00) Amman"
  - "FLE Standard Time|(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius"
  - "GTB Standard Time|(UTC+02:00) Athens, Bucharest"
  - "Libya Standard Time|(UTC+02:00) Tripoli"
  - "Egypt Standard Time|(UTC+02:00) Cairo"
  - "Arabic Standard Time|(UTC+03:00) Baghdad"
  - "Turkey Standard Time|(UTC+03:00) Istanbul"
  - "Belarus Standard Time|(UTC+03:00) Minsk"
  - "Arab Standard Time|(UTC+03:00) Kuwait, Riyadh"
  - "Russian Standard Time|(UTC+03:00) Moscow, St. Petersburg, Volgograd"
  - "E. Africa Standard Time|(UTC+03:00) Nairobi"
  - "Iran Standard Time|(UTC+03:30) Tehran"
  - "Azerbaijan Standard Time|(UTC+04:00) Baku"
  - "Mauritius Standard Time|(UTC+04:00) Port Louis"
  - "Russia Time Zone 3|(UTC+04:00) Izhevsk, Samara"
  - "Saratov Standard Time|(UTC+04:00) Saratov"
  - "Caucasus Standard Time|(UTC+04:00) Yerevan"
  - "Arabian Standard Time|(UTC+04:00) Abu Dhabi, Muscat"
  - "Astrakhan Standard Time|(UTC+04:00) Astrakhan, Ulyanovsk"
  - "Georgian Standard Time|(UTC+04:00) Tbilisi"
  - "Afghanistan Standard Time|(UTC+04:30) Kabul"
  - "Pakistan Standard Time|(UTC+05:00) Islamabad, Karachi"
  - "Ekaterinburg Standard Time|(UTC+05:00) Ekaterinburg"
  - "West Asia Standard Time|(UTC+05:00) Ashgabat, Tashkent"
  - "Sri Lanka Standard Time|(UTC+05:30) Sri Jayawardenepura"
  - "India Standard Time|(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi"
  - "Nepal Standard Time|(UTC+05:45) Kathmandu"
  - "Omsk Standard Time|(UTC+06:00) Omsk"
  - "Bangladesh Standard Time|(UTC+06:00) Dhaka"
  - "Central Asia Standard Time|(UTC+06:00) Astana"
  - "Myanmar Standard Time|(UTC+06:30) Yangon (Rangoon)"
  - "SE Asia Standard Time|(UTC+07:00) Bangkok, Hanoi, Jakarta"
  - "W. Mongolia Standard Time|(UTC+07:00) Hovd"
  - "Tomsk Standard Time|(UTC+07:00) Tomsk"
  - "Altai Standard Time|(UTC+07:00) Barnaul, Gorno-Altaysk"
  - "North Asia Standard Time|(UTC+07:00) Krasnoyarsk"
  - "N. Central Asia Standard Time|(UTC+07:00) Novosibirsk"
  - "Taipei Standard Time|(UTC+08:00) Taipei"
  - "Ulaanbaatar Standard Time|(UTC+08:00) Ulaanbaatar"
  - "Singapore Standard Time|(UTC+08:00) Kuala Lumpur, Singapore"
  - "North Asia East Standard Time|(UTC+08:00) Irkutsk"
  - "W. Australia Standard Time|(UTC+08:00) Perth"
  - "China Standard Time|(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi"
  - "North Korea Standard Time|(UTC+08:30) Pyongyang"
  - "Aus Central W. Standard Time|(UTC+08:45) Eucla"
  - "Transbaikal Standard Time|(UTC+09:00) Chita"
  - "Yakutsk Standard Time|(UTC+09:00) Yakutsk"
  - "Tokyo Standard Time|(UTC+09:00) Osaka, Sapporo, Tokyo"
  - "Korea Standard Time|(UTC+09:00) Seoul"
  - "Cen. Australia Standard Time|(UTC+09:30) Adelaide"
  - "AUS Central Standard Time|(UTC+09:30) Darwin"
  - "AUS Eastern Standard Time|(UTC+10:00) Canberra, Melbourne, Sydney"
  - "Vladivostok Standard Time|(UTC+10:00) Vladivostok"
  - "E. Australia Standard Time|(UTC+10:00) Brisbane"
  - "West Pacific Standard Time|(UTC+10:00) Guam, Port Moresby"
  - "Tasmania Standard Time|(UTC+10:00) Hobart"
  - "Lord Howe Standard Time|(UTC+10:30) Lord Howe Island"
  - "Central Pacific Standard Time|(UTC+11:00) Solomon Is., New Caledonia"
  - "Sakhalin Standard Time|(UTC+11:00) Sakhalin"
  - "Norfolk Standard Time|(UTC+11:00) Norfolk Island"
  - "Bougainville Standard Time|(UTC+11:00) Bougainville Island"
  - "Magadan Standard Time|(UTC+11:00) Magadan"
  - "Russia Time Zone 10|(UTC+11:00) Chokurdakh"
  - "Fiji Standard Time|(UTC+12:00) Fiji"
  - "Russia Time Zone 11|(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky"
  - "UTC+12|(UTC+12:00) Coordinated Universal Time+12"
  - "Kamchatka Standard Time|(UTC+12:00) Petropavlovsk-Kamchatsky - Old"
  - "New Zealand Standard Time|(UTC+12:00) Auckland, Wellington"
  - "Chatham Islands Standard Time|(UTC+12:45) Chatham Islands"
  - "UTC+13|(UTC+13:00) Coordinated Universal Time+13"
  - "Tonga Standard Time|(UTC+13:00) Nuku'alofa"
  - "Samoa Standard Time|(UTC+13:00) Samoa"
  - "Line Islands Standard Time|(UTC+14:00) Kiritimati Island"

- **papersize**: Define the paper size in which PDF reports are created. Choose between:
  - "none": Do not specify a paper format. The size is set automatically.
  - "a4": Use German DIN A4 format.
  - "a3": Use DIN A3 format.
  - "a2": Use DIN A2 format.
  - "legal": Use North American legal paper format.
  - "letter": Use North American letter paper format.
  - "ledger": Use North American ledger paper format.

- **orientation**: Define the page orientation for the data in PDF reports. Choose between:
  - “0” = Portrait: Use portrait mode for the page orientation.
  - “1” = Landscape: Use landscape mode for the page orientation. The landscape format is designed to properly show data tables of sensors with many channels. Other parts of the report will remain in portrait mode and do not re-size to the landscape format.

- **scheduletype**: 
  - "0": No schedule (run interactively/on-demand only): Only use the options on the Run Now tab to start generating this report manually.
  - "1": Every full hour: Run this report every 60 minutes.
  - "2" #Every day at a specific hour: Run this report every 24 hours.
  - "3" #Every specific day of a week: Run this report every 7 days. Specify the day below.
  - "4" #Every specific day of a month: Run this report on a specific day every month. Specify below
  - "6" #The day after a quarter has finished (i.e. on 1. April for the 1. January - 31. March Quarter): Run this report for every quarter of the year.
  - "5" #Every specific date. Run this report on a specific date every year. (Not implemented)

- **maildisk**: This setting is used only if you set the “scheduletype” to a value different to “0”. Define what to do with a finished report. Choose between:
  - "0": Save report to disk and send it by email: Create a PDF file and, depending on the Data Files setting, data files of the report, store it, and send it via email. You find the report in your emails and on the Stored Reports tab. Define an email address in "emailaddress" option.
  - "1": Save report to disk only: reate a PDF file and, depending on the Data Files setting, data files of the report and store it. Once finished, you find them on the Stored Reports tab. You receive also a ToDo ticket from PRTG. By default, PRTG sends out a notification email to the administrator in this case.
  - "2": Send report by email only: Create a PDF file and, depending on the Data Files setting, data files of the report and send them via email once finished. With this option the report is not permanently stored in PRTG. Define an email address below.

- **emailaddress**: This setting is used only if you select a send by email option above. Enter a valid email address to which PRTG sends the report. To enter more addresses, separate them by comma. PRTG sends a message with all recipients in the "To" field of the email.
- **emailgroup**: This setting is used only if you select a send by email option above. Set a user group to send an email with the report to all members of this group. You can edit user groups in PRTG System Administration—User Groups.
- **usecompression**: This setting is used only if you select a send by email option above. Define if PRTG will compress the attached report files before sending them out. Choose between:
  - "0": Send files uncompressed (default): PRTG sends the report files by email in their original size.
  - "1": Send all in one ZIP file: PRTG will compress the report files to a ZIP file before they are sent by email.

- **dataperiod**: Define the time span the report covers. Choose between:
  - "0": Current: Use monitoring data of the current period. Define the period type below.
  - "1": Previous: Use monitoring data of the last period. Define the period type below.

- **reporttype**: Define the type of period you want to create a report for. Choose between:
  - "0": Day
  - "1": Week
  - "2": Month
  - "3": Quarter (January-March, April-June, etc.)
  - "4": Year

- **accessrights_group**: User Group Access. Define which user group(s) will have access to the object that you are editing. You must use one user groups from your PRTG setup. 

- **accessrights_value**: User group access right. For the previous user group, you can choose from the following access rights:
  - "0": None: Users in this group cannot see or edit the object. The object does not show up in lists.
  - "100": Read: Users in this group can see the object and review its settings.
  - "200": Write: Users in this group can see the object, as well as review and edit its settings. However, they cannot edit access rights settings.
  - "400": Full: Users in this group can see the object, as well as review and edit its settings as well as edit access rights.

- **sensors**: list of sensors.

#### Report sensor configuration option

- **internal_sensorId**: This is the internal id defined in the sensor configuration. This id is used to get the name of the sensor.

- **channels**: list of channels

##### Report sensor channel configuration option

- **channelId**: Identifier of the channel
