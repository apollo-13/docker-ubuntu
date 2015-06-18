#!/bin/bash

if [ "$ENVIRONMENT" != "development" ]
then

    aws s3 cp s3://apollo13-ecs-config/config-service.sh /etc/profile.d && source /etc/profile

    if [ "$APOLLO13_GIT_DIRECTORY" -a "$APOLLO13_GIT_PULL_LATEST" = true ]
    then
        ./git-pull.sh
    fi

fi

export APOLLO13_CONFIG_SERVICE_HOST=${APOLLO13_CONFIG_SERVICE_HOST:-config-service}
export APOLLO13_CONFIG_SERVICE_PORT=${APOLLO13_CONFIG_SERVICE_PORT:-6379}
export APOLLO13_CONFIG_SERVICE_DB=${APOLLO13_CONFIG_SERVICE_DB:-0}

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

		configOptionEnv="APOLLO13_`echo ${configOptionAlias/-/_} | tr '[:lower:]' '[:upper:]'`"
		export ${configOptionEnv}=`config-service-get $configOption`

	done
fi

export CONTAINER_IPV4_ADDRESS="`ip addr list eth0 | grep "inet "  | cut -d' ' -f6 | cut -d/ -f1`"
export CONTAINER_IPV6_ADDRESS="`ip addr list eth0 | grep "inet6 " | cut -d' ' -f6 | cut -d/ -f1`"

exec "$@"
