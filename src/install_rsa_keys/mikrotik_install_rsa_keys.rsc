#
# Install SSH Public Keys 
#
# v1.0.0 2017-12-23 Basic functions (Pavel Kim)
# v1.0.1 2017-12-23 Catching error now (Pavel Kim)
# v1.0.2 2017-12-23 Fixed bug with fetch goes in other thread or something (Pavel Kim)
# v1.0.3 2020-03-10 Updated key paths (Pavel Kim)
# v1.0.4 2020-10-31 Updated key paths (Pavel Kim)
# v2.0.0 2020-11-07 Versioning changed. (Pavel Kim)
#
#
# It just adds public keys for a user. Duplicates possible.
# User should be created before running this script.
# 
#
# Usage example:
# /tool fetch url="https://github.com/pavelkim/mikrotik/releases/latest/download/mikrotik_install_rsa_keys.rsc" dst-path="scripts/mikrotik_install_rsa_keys.rsc"
# /import scripts/mikrotik_install_rsa_keys.rsc
# /user ssh-keys print
#
# Variables:
# ----------
# :local influxDBURL "https://influx.db.server:port/endpoint"
#

:local keys { 
		"username"=( "https://url.to/your/rsa.key", "https://url.to/your/second.rsa.key" )
}
:local keyFilePath
:local keyFileID 0
:local version dev

:log info message="Start importing RSA Keys (v.$version)."

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
				:delay delay-time=0.5s
			} while=( [ /file find name="$keyFilePath" ] = "" );

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
