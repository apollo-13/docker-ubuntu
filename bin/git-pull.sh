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

GIT_CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ ${APOLLO13_GIT_BRANCH} != ${GIT_CURRENT_BRANCH} -a -d .git ]
then

    # A branch $APOLLO13_GIT_BRANCH was requested, but different branch was cloned. We cannot
    # switch branch because we use shallow clone. Therefore deleting the current clone and cloning
    # correct branch instead.
    #
    # This completely erases the content of $APOLLO13_GIT_DIRECTORY, therefore adding a safety
    # check that the directory contains .git to prevent accidental deletion of incorrect directory
    # (i.e. when incorrect environment variables would be set).

    echo "Cloning latest $APOLLO13_GIT_DIRECTORY branch $APOLLO13_GIT_BRANCH"

    GIT_REMOTE_REPOSITORY=$(git config --get remote.origin.url)
    find -mindepth 1 -delete
    git clone --depth 1 --branch ${APOLLO13_GIT_BRANCH} ${GIT_REMOTE_REPOSITORY} .

else

    # Pulling the same branch that was cloned (e.g. in Dockerfile), pull only the changes since last
    # clone or pull.

    git fetch origin > /dev/null

    LOCAL_REVISION=$(git rev-parse @)
    REMOTE_REVISION=$(git rev-parse @{u})

    if [ $LOCAL_REVISION = $REMOTE_REVISION ]
    then
        exit 64 # already running latest revision, do nothing
    fi

    echo "Pulling latest $APOLLO13_GIT_DIRECTORY branch $APOLLO13_GIT_BRANCH"

    git checkout origin/$APOLLO13_GIT_BRANCH
    git branch -D $APOLLO13_GIT_BRANCH
    git checkout -b $APOLLO13_GIT_BRANCH

fi

exit 0
