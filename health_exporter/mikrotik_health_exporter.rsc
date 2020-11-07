#
# Health Monitoring
#
# v1.0.0 2020-11-06 Initial version. (Pavel Kim)
# v1.1.0 2020-11-07 Better TSDB write request payload rendering. (Pavel Kim)
# v1.1.1 2020-11-07 Not rendering TSDB write item for empty values. (Pavel Kim)
# v1.1.2 2020-11-07 Platform name tag dropped. (Pavel Kim)
# v1.1.3 2020-11-07 Acquiring InfluxDB URL from the environment. (Pavel Kim)
#
# Usage example:
# --------------
# /tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_health_exporter.rsc" dst-path="scripts/mikrotik_health_exporter.rsc"
# /import scripts/mikrotik_health_exporter.rsc
# :global influxDBURL ""
# /system scheduler add interval=1m name=mikrotik_health_exporter on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_health_exporter.rsc" policy=read,test start-time=startup
#
# Variables:
# ----------
# :local influxDBURL "https://influx.db.server:port/endpoint"
#


:local version "dev"
:local scriptRunDatetime
:local deviceIdentity
:local deviceTemperature
:local deviceMemFree
:local deviceMemTotal
:local deviceDiskFree
:local deviceDiskTotal
:local deviceDiskBadBlocks
:local deviceDiskWriteSectSinceReboot
:local deviceDiskWriteSectTotal
:local deviceCPULoad
:local currentPostRequestPayloadPart
:local postRequestPayloadParts ({})
:local postRequestPayload

:log info message=" *** Health Monitoring v.$version START ***"

:if ([:tostr [:typeof $influxDBURL ]] = "nothing" ) do={
	:error "Error: can't read out variable \$influxDBURL. InfluxDB URL not set, exiting."
}

:set scriptRunDatetime ( [:tostr [ /system clock get date ]] . " " . [:tostr [ /system clock get time ]] )
:set deviceIdentity ( [ /system identity get name] )
:set deviceTemperature ( [ /system health get temperature ] )
:set deviceMemFree ( [ /system resource get free-memory ] )
:set deviceMemTotal ( [ /system resource get total-memory ] )
:set deviceDiskFree ( [ /system resource get free-hdd-space ] )
:set deviceDiskTotal ( [ /system resource get total-hdd-space ] )
:set deviceDiskBadBlocks ( [ /system resource get bad-blocks ] )
:set deviceDiskWriteSectSinceReboot ( [ /system resource get write-sect-since-reboot ] )
:set deviceDiskWriteSectTotal ( [ /system resource get write-sect-total ] )
:set deviceCPULoad ( [ /system resource get cpu-load ] )

:log debug message="HealthMon: scriptRunDatetime: '$scriptRunDatetime'"
:log debug message="HealthMon: deviceIdentity: '$deviceIdentity'"
:log debug message="HealthMon: deviceTemperature: '$deviceTemperature'"
:log debug message="HealthMon: deviceMemFree: '$deviceMemFree'"
:log debug message="HealthMon: deviceMemTotal: '$deviceMemTotal'"
:log debug message="HealthMon: deviceDiskFree: '$deviceDiskFree'"
:log debug message="HealthMon: deviceDiskTotal: '$deviceDiskTotal'"
:log debug message="HealthMon: deviceDiskBadBlocks: '$deviceDiskBadBlocks'"
:log debug message="HealthMon: deviceDiskWriteSectSinceReboot: '$deviceDiskWriteSectSinceReboot'"
:log debug message="HealthMon: deviceDiskWriteSectTotal: '$deviceDiskWriteSectTotal'"
:log debug message="HealthMon: deviceCPULoad: '$deviceCPULoad'"

:set postRequestPayloadParts {
	"deviceTemperature"="$deviceTemperature";
	"deviceMemFree"="$deviceMemFree";
	"deviceMemTotal"="$deviceMemTotal";
	"deviceDiskFree"="$deviceDiskFree";
	"deviceDiskTotal"="$deviceDiskTotal";
	"deviceDiskBadBlocks"="$deviceDiskBadBlocks";
	"deviceDiskWriteSectSinceReboot"="$deviceDiskWriteSectSinceReboot";
	"deviceDiskWriteSectTotal"="$deviceDiskWriteSectTotal";
	"deviceCPULoad"="$deviceCPULoad";
}

:foreach postRequestPayloadPartName,postRequestPayloadPart in=$postRequestPayloadParts do={

	:if ( [:len ($postRequestPayloadParts->"$postRequestPayloadPartName") ] > 0 ) do={
		:set currentPostRequestPayloadPart ("monitoring,instance=$deviceIdentity" . " " . $postRequestPayloadPartName . "=" . $postRequestPayloadParts->"$postRequestPayloadPartName")
		:set postRequestPayload ( "$currentPostRequestPayloadPart" . "\n" . "$postRequestPayload" )
	
	} else={
		:log warning message="$postRequestPayloadPartName is empty. Omitting."
	};
}

/tool fetch url="$influxDBURL" keep-result=no check-certificate=no http-method=post http-data="$postRequestPayload"
:log info message=" *** Health Monitoring FINISH ***"
