#!/bin/bash

# Load configuration for the server.
#
# {$SERVER_NAME}_config setting contains list of settings the server depens on. Alias can be
# optionally used:
#
# Example:
# Make settings 'rabbitmq001-master_host' accessible under alias 'amqp_host'
# rabbitmq001-master_host:rabbitmq_host

if [ "$SERVER_NAME" ]
then
	dependencies=`config-service-get ${SERVER_NAME}_config`
	for configOption in $dependencies
	do

		if [[ $configOption == *:* ]]
		then
			IFS=":" read -a configOptionTokens <<< $configOption
			configOption=${configOptionTokens[0]}
			configOptionAlias=${configOptionTokens[1]}
		else
			configOptionAlias=$configOption
		fi

		configOptionEnv="APOLLO13_`echo ${configOptionAlias//-/_} | tr '[:lower:]' '[:upper:]'`"
		export ${configOptionEnv}=`config-service-get $configOption`

	done
fi

# Persisting configuration settings from environment for future usage
echo "" > /etc/profile.d/apollo13.sh
for configOption in `printenv`
do
    if [[ $configOption == APOLLO13*=* ]]
    then
        echo "export ${configOption}" >> /etc/profile.d/apollo13.sh
    fi
done

