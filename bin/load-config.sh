#!/bin/bash

# Load configuration for the server.
#
# {$SERVER_NAME}_config setting contains list of settings the server depens on. Alias can be
# optionally used:
#
# Example:
# Make settings 'rabbitmq001-master_host' accessible under alias 'amqp_host'
# rabbitmq001-master_host:rabbitmq_host
#
# Script returns exit status 0 if configuration is not changed, and exit status 1 if configuration is changed.

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
TMP_FILE=`mktemp`
echo "" > $TMP_FILE
for configOption in `printenv | sort`
do
    if [[ $configOption == APOLLO13*=* ]]
    then
        echo "export ${configOption}" >> $TMP_FILE
    fi
done

cmp -s $TMP_FILE /etc/profile.d/apollo13.sh
CONFIGURATION_UPDATED=$?
mv -f $TMP_FILE /etc/profile.d/apollo13.sh

exit $CONFIGURATION_UPDATED
