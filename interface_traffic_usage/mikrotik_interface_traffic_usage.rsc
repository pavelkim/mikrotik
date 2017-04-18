#
# Interface Traffic Usage 
#
# v1.0 2017-04-18 Script works with Ethernet Interfaces' comments. Resets counters. 
#

:local currentItemComment
:local currentItemCommentBeforeData
:local currentItemCommentAfterData
:local currentItemCommentBytes
:local currentItemNewComment

:local currentItemBytesNowRx
:local currentItemBytesNowTx
:local currentItemBytesNowTotal

:local posDataBegin
:local posDataEnd
:local posDataDelimiter
:local posCommentEnd 

:local scriptRunDatetime

:global removeSpaces do={

	:local inputLine $1

	:local posEnd
	:local posCurrentDelimiter
	:local partBeforeDelimiter
	:local partAfterDelimiter

	:local i 0
	:while (  [:tonum [:find "$inputLine" "\_"] ] > 0 and $i < 6 ) do={
		:set posEnd [:len $inputLine ]
		:set posCurrentDelimiter [:find $inputLine "\_"]
		:set partBeforeDelimiter [:pick $inputLine 0 $posCurrentDelimiter]
		:set partAfterDelimiter [:pick $inputLine ($posCurrentDelimiter + 1) $posEnd ]

		:set inputLine  ("$partBeforeDelimiter" . "$partAfterDelimiter") 
		:set i ($i + 1)

	}

	:return [:tonum $inputLine]

}

:log info message=" *** Interface Traffic Usage START ***"
:set scriptRunDatetime ( [:tostr [/system clock get date]] . " " . [:tostr [/system clock get time]] )

:foreach itemID in=[/interface ethernet find comment~"\\{traffic:.*\\}"] do={
	:log info message="ITU: processing item $itemID"

	:set currentItemComment [ /interface ethernet get $itemID comment ]
	:log info message="ITU: Item: $itemID, Comment: '$currentItemComment'"

	:if ([:find $currentItemComment ":"] != "") do={
		:log info message="ITU: Item: $itemID Delimiter found, hope syntax is correct"

		:set posDataBegin [ :find $currentItemComment "{" ]
		:set posDataEnd [ :find $currentItemComment "}" ]
		:set posDataDelimiter [ :find $currentItemComment ":" ]
		:set posCommentEnd [ :len $currentItemComment ]

		:set currentItemCommentBytes [ :pick $currentItemComment ($posDataDelimiter + 1) ($posDataEnd) ]
		:set currentItemCommentBeforeData [ :pick $currentItemComment 0 $posDataBegin ]
		:set currentItemCommentAfterData [ :pick $currentItemComment ($posDataEnd + 1) $posCommentEnd ]
		
		:log info message="ITU: Item: $itemID, Bytes: '$currentItemCommentBytes'"
		:log info message="ITU: Item: $itemID, Comment before data: '$currentItemCommentBeforeData'"
		:log info message="ITU: Item: $itemID, Comment after data: '$currentItemCommentAfterData'"

		:set currentItemBytesNowRx [ $removeSpaces [:tostr [ /interface ethernet get number=$itemID rx-bytes ] ] ]
		:set currentItemBytesNowTx [ $removeSpaces [:tostr [ /interface ethernet get number=$itemID tx-bytes ] ] ]
		:set currentItemBytesNowTotal ( $currentItemBytesNowRx + $currentItemBytesNowTx ) 

		/interface ethernet reset-counters numbers=$itemID

		:log info message=( "ITU: Item: " . $itemID . ", RX Bytes: " . $currentItemBytesNowRx . " TX Bytes: " .$currentItemBytesNowTx)

		:if ( $currentItemCommentBytes = "null" ) do={
			:log info message="ITU: Item: $itemID A first start. Just writing current data instead of 'null'."
			:set currentItemNewComment ( $currentItemCommentBeforeData . "{traffic:" . ($currentItemBytesNowRx + $currentItemBytesNowTx) . "}" . $currentItemCommentAfterData )
			/interface ethernet set numbers=$itemID comment="$currentItemNewComment"
		} else={
			:log info message="ITU: Item: $itemID Updating data and sending a notification."
			:set currentItemNewComment ( $currentItemCommentBeforeData . "{traffic:" . ($currentItemBytesNowRx + $currentItemBytesNowTx) . "}" . $currentItemCommentAfterData )
			/interface ethernet set numbers=$itemID comment="$currentItemNewComment"
			# /tool fetch url="$notificationServiceURL" 
		}


	}


}

:log info message=" *** Interface Traffic Usage FINISH ***"

