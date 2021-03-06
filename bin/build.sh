#!/bin/bash

APOLLO13_GIT_DIRECTORY=${1:-$APOLLO13_GIT_DIRECTORY}

if [ -z "$APOLLO13_GIT_DIRECTORY" ]
then
    echo "Error: \$APOLLO13_GIT_DIRECTORY not defined, cannot perform build."
    exit 1
fi

if ! cd "$APOLLO13_GIT_DIRECTORY" 2>/dev/null
then
    echo "Error: Directory $APOLLO13_GIT_DIRECTORY does not exist."
    exit 1
fi

if [ -f composer.json ]
then
    composer install --prefer-dist --no-interaction
fi

if [ -f package.json ]
then
    npm config set registry http://registry.npmjs.org/
    npm --loglevel info install --no-optional
fi
