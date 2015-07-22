#!/bin/bash

CONTAINER_LAUNCHED=`[ -f /.container_launched ] && echo true || echo false`
touch /.container_launched

if [ "$CONTAINER_LAUNCHED" = false -a "$EC2_ENVIRONMENT" != false ]
then
    # Load config service connection details
    aws s3 cp s3://apollo13-ecs-config/config-service.sh /etc/profile.d && source /etc/profile

    export HOST_IPV4_ADDRESS="`curl -s --connect-timeout 30 http://169.254.169.254/latest/meta-data/local-ipv4`"
    export HOST_PUBLIC_IPV4_ADDRESS="`curl -s --connect-timeout 30 http://169.254.169.254/latest/meta-data/public-ipv4`"

    if [ -z "$HOST_IPV4_ADDRESS" ]
    then
        echo "EC2 container IPV4 address not detected, probably not in Amazon environment. Launch container with EC2_ENVIRONMENT=false enviroment variable."
        exit 1
    fi

    # Start CloudWatch Logs Agent if config file contains at least one additional section except of the [general].
    if [ `cat /var/awslogs/etc/awslogs.conf | grep -G "^\[" | wc -l` -gt 1 ]
    then
        sed -i 's/{server_name}/'"$SERVER_NAME"'/' /var/awslogs/etc/awslogs.conf
        service awslogs start
    fi

else
    source /etc/profile
fi

export CONTAINER_IPV4_ADDRESS="`ip addr list eth0 | grep "inet "  | cut -d' ' -f6 | cut -d/ -f1`"
export CONTAINER_IPV6_ADDRESS="`ip addr list eth0 | grep "inet6 " | cut -d' ' -f6 | cut -d/ -f1`"
export HOST_IPV4_ADDRESS=${HOST_IPV4_ADDRESS:-${CONTAINER_IPV4_ADDRESS}}
export HOST_PUBLIC_IPV4_ADDRESS=${HOST_PUBLIC_IPV4_ADDRESS:-${HOST_IPV4_ADDRESS}}

export APOLLO13_CONFIG_SERVICE_HOST=${APOLLO13_CONFIG_SERVICE_HOST:-config-service}
export APOLLO13_CONFIG_SERVICE_PORT=${APOLLO13_CONFIG_SERVICE_PORT:-6379}
export APOLLO13_CONFIG_SERVICE_DB=${APOLLO13_CONFIG_SERVICE_DB:-0}

load-config.sh
source /etc/profile

if [ "$APOLLO13_GIT_BRANCH" -a "$APOLLO13_GIT_DIRECTORY" -a "$APOLLO13_GIT_PULL_LATEST" = true -a "$CONTAINER_LAUNCHED" = false ]
then
	echo "Updating $APOLLO13_GIT_DIRECTORY repo state for branch $APOLLO13_GIT_BRANCH."
    update.sh
fi

exec "$@"
