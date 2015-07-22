#!/bin/bash
#
# Appends a new sections to AWS CloudWatch Logs Agent configuration file from a temporary file
# that is deleted aftewards.
#
# The syntax of the configuration file is described here:
# http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/AgentReference.html
#
# In addition to predefined variables {server_name} variable can be used that will be replaced
# with $SERVER_NAME environment variable.
#
# Usage: add-awslogs-config.sh [TMP_AWSLOGS_CONF_FILE]

if [ "$#" -ne 1 ]
then
    echo "Usage: add-awslogs-config.sh [TMP_AWSLOGS_CONF_FILE]"
    exit 1
fi

if [ ! -f "$1" ]
then
    echo "File not found: $1"
    exit 1
fi

cat "$1" >> /var/awslogs/etc/awslogs.conf
rm -f "$1"

