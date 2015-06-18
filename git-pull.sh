#!/bin/bash
#
# This script performs 'git pull' in the directory $APOLLO13_GIT_DIRECTORY and executes 'composer install'
# if composer.json file is present in the director.

APOLLO13_GIT_BRANCH=${APOLLO13_GIT_BRANCH:-master}

if [ -z "$APOLLO13_GIT_DIRECTORY" ]
then
    echo "Error: \$APOLLO13_GIT_DIRECTORY not defined, cannot perform git pull."
    exit 1
fi

if ! cd "$APOLLO13_GIT_DIRECTORY" 2>/dev/null
then
    echo "Error: Directory $APOLLO13_GIT_DIRECTORY does not exist."
    exit 1
fi

git fetch origin > /dev/null

LOCAL_REVISION=$(git rev-parse @)
REMOTE_REVISION=$(git rev-parse @{u})

if [ $LOCAL_REVISION = $REMOTE_REVISION ]
then
    # already running latest revision, do nothing
    exit 0
fi

echo "Pulling latest $APOLLO13_GIT_DIRECTORY"

git checkout origin/$APOLLO13_GIT_BRANCH
git branch -D $APOLLO13_GIT_BRANCH
git checkout -b $APOLLO13_GIT_BRANCH

if [ -f composer.json ]
then
    composer install
fi
