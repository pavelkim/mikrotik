#
# Install SSH Public Keys
#
# It just adds public keys for a user. Duplicates possible.
# User should be created before running this script.
#
# Usage example:
# /tool fetch url="https://pavelkim.github.io/dist/mikrotik/latest/mikrotik_install_rsa_keys.rsc" dst-path="scripts/mikrotik_install_rsa_keys.rsc"
# /import scripts/mikrotik_install_rsa_keys.rsc
# /user ssh-keys print
#
# Variables:
# ----------
# :global keys { "username"=( "url", "url" ) }
#

:global keys

:local keyFilePath
:local keyFileID 0
:local retryAttemptsLimit 10
:local retryAttempts 1
:local version DEV

:log info message="Start importing RSA Keys (v$version)."

:if ([:tostr [:typeof $keys ]] = "nothing" ) do={
	:error "Error: can't read out variable \$keys. Keys and users are not set, exiting."
}

foreach accountName,keyURLList in=$keys do={
	:log info message="Processing keys for account '$accountName'"

	foreach keyURL in=$keyURLList do={
		:log info message="Got an URL to a key for $accountName '$keyURL'"

		:set keyFileID ($keyFileID + 1)
		:set keyFilePath "$accountName_$keyFileID.pub"
		:log info message="Key is going to be saved as '$keyFilePath'"
		
		:log info message="Retrieving RSA Key from URL '$keyURL' to file '$keyFilePath'"
		:do {
			
			/tool fetch mode="http" url=$keyURL dst-path="$keyFilePath"
			
			:do {
				:log info message="File isn't ready yet. Waiting until file '$keyFilePath' appears"
				:delay delay-time=0.5
				:set retryAttempts ( $retryAttempts + 1 )
			} while=(( [ /file find name="$keyFilePath" ] = "" ) && ( $retryAttempts < $retryAttemptsLimit ));

		} on-error={
			:log error message="Couldn't download or save RSA Key. File: '$keyFilePath', URL: '$keyURL'"
			:error "Couldn't download or save RSA Key. Stop!"
		}
		
		:log info message="Importing key file '$keyFilePath' for user '$accountName'"
		:do {
			/user ssh-keys import public-key-file="$keyFilePath" user="$accountName"
		} on-error={
			:log error message="Couldn't import RSA Key. User: '$accountName', File: '$keyFilePath', URL: '$keyURL'"
		}

	};
};

:log info message="Done importing RSA Keys."
