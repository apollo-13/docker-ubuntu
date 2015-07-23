#!/bin/bash
#
# Periodically polls configuration from configuration service, and reloads the service running in the container if
# the configuration has changed.

function log {
    echo "`date +"%Y-%m-%d %H:%M:%S"`: $1"
}

log "> configuration watcher started"

while true
do
    sleep 60
    log "> checking configuration"
    load-config.sh || (
        log "configuration changed, reloading"
        service-reload.sh
    )
done

log "> configuration watcher stopped"
