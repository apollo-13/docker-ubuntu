#!/bin/bash

CONTAINER_LAUNCHED=`[ -f /.container_launched ] && echo true || echo false`
touch /.container_launched

if [ "$CONTAINER_LAUNCHED" = false -a "$EC2_ENVIRONMENT" != false ]
then
    # Load config service connection details
    AWS_REGION=eu-west-1

    if [ -z "$APOLLO13_EC2_CONFIG_SERVICE_S3_PATH" ]
    then
        EC2_INSTANCE_ID=`curl -s --connect-timeout 30 http://169.254.169.254/latest/meta-data/instance-id`
        EC2_VPC_ID=`aws --region $AWS_REGION ec2 describe-instances --instance-ids $EC2_INSTANCE_ID | grep \"VpcId\" | head -1 | cut -d: -f2 | sed 's/[^a-zA-Z0-9_-]*//g'`
        EC2_ENVIRONMENT_TAG=`aws --region $AWS_REGION ec2 describe-tags --filters Name=resource-type,Values=instance Name=resource-id,Values=$EC2_INSTANCE_ID Name=key,Values=Environment | grep \"Value\" | head -1 | cut -d: -f2 | sed 's/[^a-zA-Z0-9_-]*//g'`
        APOLLO13_EC2_CONFIG_SERVICE_S3_PATH="apollo13-ecs-config/config-service_${EC2_VPC_ID}_${EC2_ENVIRONMENT_TAG}.sh"
    fi

    aws s3 cp "s3://${APOLLO13_EC2_CONFIG_SERVICE_S3_PATH}" /etc/profile.d/config-service.sh && source /etc/profile

    export HOST_IPV4_ADDRESS="`curl -s --connect-timeout 30 http://169.254.169.254/latest/meta-data/local-ipv4`"
    export HOST_PUBLIC_IPV4_ADDRESS="`curl -s --connect-timeout 30 http://169.254.169.254/latest/meta-data/public-ipv4`"

    if [ -z "$HOST_IPV4_ADDRESS" ]
    then
        echo "EC2 container IPV4 address not detected, probably not in Amazon environment. Launch container with EC2_ENVIRONMENT=false enviroment variable."
        exit 1
    fi

    for file in /var/awslogs/etc/*
    do
        sed -i 's/{server_name}/'"$SERVER_NAME"'/' $file
    done

    # Start CloudWatch Logs Agent if config file contains at least one additional section except of the [general].
    if [ `cat /var/awslogs/etc/awslogs.conf | grep -G "^\[" | wc -l` -gt 1 ]
    then
        service awslogs start
    fi

else
    source /etc/profile
fi

if [ -z "$DOCKERCLOUD_IP_ADDRESS" ]
then
    export CONTAINER_IPV4_ADDRESS="`ip addr list eth0 | grep "inet "  | cut -d' ' -f6 | cut -d/ -f1`"
else
    export CONTAINER_IPV4_ADDRESS="`echo $DOCKERCLOUD_IP_ADDRESS | cut -d/ -f 1`"
fi

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

if [ "$APOLLO13_GIT_DIRECTORY" ]
then
    export APOLLO13_GIT_VERSION_TAG=$(cd $APOLLO13_GIT_DIRECTORY && git tag --points-at HEAD | grep -P "^v?\d" | head -n 1 | sed 's~^v~~')
fi

if [ "$CONTAINER_LAUNCHED" = false ]
then
    config-watcher.sh >> /var/log/config-watcher.log &

    if [ "$APOLLO13_CONTAINER_ONLAUNCH" ]
    then
        bash -c "$APOLLO13_CONTAINER_ONLAUNCH"
    fi
fi

exec "$@"
