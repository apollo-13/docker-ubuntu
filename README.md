# Ubuntu #

Docker container used as base for all other Apollo13 docker containers. Contains:

* Ubuntu
* GIT
* Midnight Commander (only for convenience)
* TERM environment variable for flawless run of console applications like mc, nano, ...
* environment initialization script *env.sh* that:
    * loads settings required to initialize the container from Redis configuration database
    * set the current IP address into environment variables named *CONTAINER_IPV4_ADDRESS* and *CONTAINER_IPV6_ADDRESS*

Build of this container is located in private Docker hub repository. In order to use private repositories you must provide your login credentials:

    docker login
    docker pull apollo13/ubuntu:14.04

*docker login* needs to be executed just once, as it stores the authentication key in *~/.dockercfg* for future uses.

Alternatively you can build the image on your computer by executing the following command in the root directory
of the repository:

    docker build -t "apollo13/ubuntu:14.04" .


## Redis configuration database ##

A Redis database is required to store configuration settings.

The Redis database contains two types of configuration values:

a) *${SERVER_NAME}_config* contains list of settings this container depends on in order to run. The settings list
is whitespace separated, and optionally an alias name for the setting can be provided using syntax *settingName:aliasName*.
The settings are loaded into environment variables prefixed by *APOLLO13_.*

b) *${SERVER_NAME}_${SETTING_NAME}* - individual settings, for example: rabbitmq001-master_host

*SERVER_NAME* should be an environment variable defined in *Dockerfile* of every container that loads or save configurations settings.
The *SERVER_NAME* environment variable can be overridden when running the container, e.g. the *-e* parameter of *docker run* or
environment settings of Amazon ECS tasks.

Configuration values can be set from shell scripts by running:

    config-service-set "${SERVER_NAME}_${SETTING_NAME}" ${SETTING_VALUE}

Example:

    config-service-set "${SERVER_NAME}_host"     "$CONTAINER_IPV4_ADDRESS"
    config-service-set "${SERVER_NAME}_user"     "$USER"
    config-service-set "${SERVER_NAME}_password" "$PASS"


### Production environment ###

In production environment, connection to Redis database must be setup the following S3 bucket:

    s3://apollo13-ecs-config/config-service.sh

Example configuration:

    APOLLO13_CONFIG_SERVICE_HOST="redis.m5ki6g.ng.0001.euw1.cache.amazonaws.com"
    APOLLO13_CONFIG_SERVICE_PORT=6379
    APOLLO13_CONFIG_SERVICE_PASSWORD=""
    APOLLO13_CONFIG_SERVICE_DB=1

Redis database from Amazon Elasticache service can be used for the above.

### Development environment ###

Pull and execute redis container:

    docker pull apollo13/redis-server
    docker run -d -p 6379:6379 --name config-service redis

Link any container using the configuration service with *-l* (link) parameter while starting the container via docker run, example:

    docker run --name rabbitmq-server -d -p 5672:5672 -p 15672:15672 --link config-service:config-service apollo13/rabbitmq-server

## GIT integration ##

The container can automatically launch *git pull* (and *composer install* too if *composer.json* is present) to
accomplish launch with the latest code.

To enable this functionality you need to define the following environment variables in *Dockerfile* of a container
derived from *apollo13/ubuntu*

    ENV APOLLO13_GIT_DIRECTORY /var/www/myproject
    ENV APOLLO13_GIT_PULL_LATEST true

*APOLLO13_GIT_DIRECTORY* contains root path to your GIT project inside the container, *APOLLO13_GIT_PULL_LATEST* enables
the actual pulling on launching the container.

In addition to that you must specify GIT branch to be pulled in APOLLO13_GIT_BRANCH environment variable. This should be
done when running the container (and not in Dockerfile), so that the docker container can be used for local development.

## Running Docker containers on Linux development host ##

When running Docker on your development host, the TCP/IP ports exposed by Docker may collide with ports of other services already
running on your development host. The workaround for this is to run Docker inside a virtual machine using [boot2docker](https://github.com/boot2docker/boot2docker-cli).

In local development environment you have to pass environment variable EC2_ENVIRONMENT=false to the container to disable
Amazon EC2 specific initialization.

## Updating the repository and building the project ##

This container contains script for updating the GIT repository to the latest version, and for performing subsequent
build process (e.g. *composer install* or *npm install*).

Script for updating GIT repository discards all local changes and should not be used if you mount your local repository
into the container instance. In such case you should only perform build.

To update the repository (discarding all local changes) by pulling the latest revision followed by building of the project, execute:

    docker exec -t -i CONTAINER_NAME_OR_ID /env.sh update.sh

To build the project (without pulling the latest revision), execute:

    docker exec -t -i CONTAINER_NAME_OR_ID /env.sh build.sh

## Launching additional commands on container start ##

The container can optionally launch additional command on its start if passed via APOLLO13_CONTAINER_ONLAUNCH environment variable. The
command is executed in bash.
