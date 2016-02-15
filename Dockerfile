FROM ubuntu:14.04
MAINTAINER Bohdan Kolecek <kolecek@apollo13.cz>

ENV DEBIAN_FRONTEND=noninteractive \

# Setting TERM to flawlessly run console applications like mc, nano when connecting interactively via docker exec
    TERM=xterm

# Prepare config file for CloudWatch Logs Agent
COPY config/aws/awslogs.conf /tmp/

# Install:
# 1. GIT for accessing repositories
# 2. MC and telnet just for convenience
# 3. redis-cli for obtaining configuration
# 4. python2, curl for installing AWS cli

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        git \
        mc \
        redis-tools \
        curl \
        python \
        telnet && \

# Install AWS CLI
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm -rf ./awscli-bundle && \
    rm ./awscli-bundle.zip && \

# Install CloudWatch Logs Agent
    curl "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py" -o "/usr/local/bin/awslogs-agent-setup.py" && \
    chmod +x /usr/local/bin/awslogs-agent-setup.py && \
    awslogs-agent-setup.py -n -r eu-west-1 -c /tmp/awslogs.conf && \
    service awslogs stop && \    

# Bash aliases
    echo "alias gitkc=\"git log --graph --oneline --all --decorate --pretty=format:\\\"%C(auto)%h%d %s (%C(green)%cr%C(reset) via %C(green)%cn%C(reset))\\\"\"" >> /etc/bash.bashrc && \

# Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add client for configuration service, entrypoint for initializing environment variables with container configuration, etc.
COPY config-service/* bin/build.sh bin/git-pull.sh bin/update.sh bin/load-config.sh bin/awslogs-add-config.sh bin/service-reload.sh bin/config-watcher.sh bin/wait-for-service.sh /usr/local/bin/

COPY bin/env.sh /

ENTRYPOINT [ "/env.sh" ]
