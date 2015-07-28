#!/bin/bash
#
# Waits till service starts listening on TCP port. Return exit code 1 on failure, exit code 0 on success.
#
# Usage:
# wait-for-service.sh PORT [MAXIMUM-ATTEMPS] [HOST]
#
# Default number of maximum attempts is 30. Default host is 127.0.0.1. There is 1 second delay between each attempt.

HOST="${3:-127.0.0.1}"
PORT="$1"
ATTEMPTS="${2:-30}"

echo "> waiting for $HOST:$PORT (maximum $ATTEMPTS attempts)"

i=0
while ! nc $HOST $PORT >/dev/null 2>&1 < /dev/null
do
    i=`expr $i + 1`
    if [ $i -ge $ATTEMPTS ]
    then
        echo "> ${HOST}:${PORT} still not reachable, giving up"
        exit 1
    fi
    sleep 1
done

echo "> ${HOST}:${PORT} is running"
exit 0
