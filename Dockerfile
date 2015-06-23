FROM ubuntu:14.04
MAINTAINER Bohdan Kolecek <bohdan.kolecek@apollo13.cz>

ENV DEBIAN_FRONTEND noninteractive

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
# Clean up

    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install SSH key for accessing GIT repositories
RUN mkdir /root/.ssh/
ADD keys/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Install AWS CLI
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm -rf ./awscli-bundle && \
    rm ./awscli-bundle.zip

# Bash aliases
RUN echo "alias gitkc=\"git log --graph --oneline --all --decorate --pretty=format:\\\"%C(auto)%h%d %s (%C(green)%cr%C(reset) via %C(green)%cn%C(reset))\\\"\"" >> /etc/bash.bashrc

# Setting TERM to flawlessly run console applications like mc, nano when connecting interactively via docker exec
ENV TERM xterm

# Add client for configuration service
ADD config-service /usr/local/bin
RUN chmod 755 /usr/local/bin/config-service-*

# Entrypoint for initializing environment variables with container configuration
ADD env.sh /env.sh
ADD git-pull.sh /git-pull.sh
RUN chmod 755 env.sh git-pull.sh

ENTRYPOINT [ "/env.sh" ]
