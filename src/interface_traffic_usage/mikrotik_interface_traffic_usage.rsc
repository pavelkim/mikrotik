#
# Interface Traffic Usage 
#
# Installation
# ============
#
# 1. Download the script
# /tool fetch url="https://pavelkim.github.io/dist/mikrotik/latest/mikrotik_interface_traffic_usage.rsc" dst-path="scripts/mikrotik_interface_traffic_usage.rsc"
# 
# 2. Set your InfluxDB write URL (https)
# :global influxDBURL "https://influx.db.server:port/endpoint"
# 
# 3. Add a scheduled start
# /system scheduler add interval=5m name=interface_traffic_usage on-event=":global influxDBURL $influxDBURL; /import scripts/mikrotik_interface_traffic_usage.rsc" policy=read,write,policy,test start-time=startup
#
#
# Results files
# =============
#
# The script stores the last taken mesurements in files named "$resultsFilenameBase_$currentItemName"
# Contents example:
# ifname:interfaceName devname:rb9000 rx:100 tx:200 ~
#


:global influxDBURL

:local version DEV

:local resultsFilenameBase "interface_traffic_usage_results"
:local resultsFilename
:local resultsContent

:local currentItemName
:local currentItemNewResult
:local currentItemResultIfname
:local currentItemResultDevname
:local currentItemResultRx
:local currentItemResultTx

:local currentItemNowRx
:local currentItemNowTx
:local currentItemNowTotal

:local posIfnameDelimiter
:local posDevnameDelimiter
:local posRxDelimiter
:local posTxDelimiter
:local posEOLSymbol
:local posResultEnd

:local postRequestPayload

:local scriptRunDatetime
:local deviceIdentity

:global removeSpaces do={

	:local inputLine $1

	:local posEnd
	:local posCurrentDelimiter
	:local partBeforeDelimiter
	:local partAfterDelimiter

	:log debug message="removeSpaces: Processing '$inputLine'"

	:local i 0
	:while (  [:tonum [:find "$inputLine" "\_"] ] > 0 and $i < 6 ) do={
		:set posEnd [:len $inputLine ]
		:set posCurrentDelimiter [:find $inputLine "\_"]
		:set partBeforeDelimiter [:pick $inputLine 0 $posCurrentDelimiter]
		:set partAfterDelimiter [:pick $inputLine ($posCurrentDelimiter + 1) $posEnd ]

		:set inputLine  ("$partBeforeDelimiter" . "$partAfterDelimiter") 
		:set i ($i + 1)

	}

	:return $inputLine

}

:log info message=" *** Interface Traffic Usage v$version START ***"
:set scriptRunDatetime ( [:tostr [/system clock get date]] . " " . [:tostr [/system clock get time]] )
:set deviceIdentity ( [/system identity get name] )

:if ([:tostr [:typeof $influxDBURL ]] = "nothing" ) do={
	:error "Error: can't read out variable \$influxDBURL. InfluxDB URL not set, exiting."
}


:foreach itemID in=[ /interface find ] do={
	:log info message="ITU: processing interface number='$itemID'"

	:set currentItemName [ /interface get $itemID name ]
	:log info message="ITU: Item: $itemID, Name: '$currentItemName'"

	:set resultsFilename "$resultsFilenameBase_$currentItemName"
	:log info message="ITU: Item: $itemID, results filename: '$resultsFilename'"

	:log info message="ITU: Item: $itemID, Looking up results file"

	if ( [:len [ /file find name="$resultsFilename.txt" ] ] > 0 ) do={
		:log info message="ITU: Item: $itemID, Found the results file, reading previous values"

		:set resultsContent [ /file get "$resultsFilename.txt" contents ]
		:log info message="ITU: Item: $itemID, Retrieved result file contents: '$resultsContent'"
	
	} else={
		:log info message="ITU: Item: $itemID, No results file found. No results are going to be analysed."

		:log info message="ITU: Item: $itemID, Preparing empty results file: $resultsFilename"
		:execute script="{}" file="$resultsFilename.txt"
		:delay delay-time=1.0

	}

	:log info message="ITU: Item: $itemID, Getting current counters"
	:set currentItemNowRx [ $removeSpaces [:tostr [ /interface get number=$itemID rx-byte ] ] ]
	:set currentItemNowTx [ $removeSpaces [:tostr [ /interface get number=$itemID tx-byte ] ] ]


	:log info message="ITU: Item: $itemID, Writing results into a file '$resultsFilename'"
	:set currentItemNewResult ( "ifname:$currentItemName devname:$deviceIdentity rx:$currentItemNowRx tx:$currentItemNowTx ~" )
	:log info message="ITU: Item: $itemID, Writing results into a file '$resultsFilename': '$currentItemNewResult'"
	/file set "$resultsFilename.txt" contents="$currentItemNewResult"

	:if ( [ :find $resultsContent "~" ] >= 0 ) do={

		:log info message=( "ITU: Item: $itemID, EOL symbol found, hopefully the syntax is correct")

		# ifname:interfaceName devname:rb9000 rx:100 tx:200 ~" )

		:set posIfnameDelimiter [ :find $resultsContent "ifname:" ]
		:set posDevnameDelimiter [ :find $resultsContent "devname:" ]
		:set posRxDelimiter [ :find $resultsContent "rx:" ]
		:set posTxDelimiter [ :find $resultsContent "tx:" ]
		:set posEOLSymbol [ :find $resultsContent "~" ]
		:set posResultEnd [ :len $resultsContent ]

		:log info message="ITU: Item: $itemID, posIfnameDelimiter=$posIfnameDelimiter posDevnameDelimiter=$posDevnameDelimiter posRxDelimiter=$posRxDelimiter posTxDelimiter=$posTxDelimiter"

		:set currentItemResultIfname  [ $removeSpaces [ :pick $resultsContent ($posIfnameDelimiter + 7) $posDevnameDelimiter ] ]
		:set currentItemResultDevname [ $removeSpaces [ :pick $resultsContent ($posDevnameDelimiter + 8) $posRxDelimiter ] ]
		:set currentItemResultRx [ $removeSpaces [ :pick $resultsContent ($posRxDelimiter + 3) $posTxDelimiter ] ]
		:set currentItemResultTx [ $removeSpaces [ :pick $resultsContent ($posTxDelimiter + 3) $posEOLSymbol ] ]

		:log info message="ITU: Item: $itemID, Restored ifName: '$currentItemResultIfname'"
		:log info message="ITU: Item: $itemID, Restored devName: '$currentItemResultDevname'"
		:log info message="ITU: Item: $itemID, Restored Rx: '$currentItemResultRx'"
		:log info message="ITU: Item: $itemID, Restored Tx: '$currentItemResultTx'"


		:if ( $currentItemResultRx > $currentItemNowRx ) do={
			:log info message="ITU: Item: $itemID, Looks like counters got reset. Rx/Tx bytes showed negative grow."
		}

		:log info message="ITU: Item: $itemID, Pushing metrics."
		
		:set postRequestPayload ( "monitoring,interface=$currentItemName,instance=$deviceIdentity traffic_rx=$currentItemNowRx" . "\n" . "monitoring,interface=$currentItemName,instance=$deviceIdentity traffic_tx=$currentItemNowTx" )
		/tool fetch url="$influxDBURL" mode="https" keep-result="no" check-certificate="no" http-method="post" http-data="$postRequestPayload"

	}

	:log info message="ITU: Finished processing interface number='$itemID'"

}


:log info message=" *** Interface Traffic Usage FINISH ***"
