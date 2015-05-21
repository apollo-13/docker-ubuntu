FROM ubuntu:14.04
MAINTAINER Bohdan Kolecek <bohdan.kolecek@apollo13.cz>

ENV DEBIAN_FRONTEND noninteractive

# Update aptitude
RUN apt-get update && \
    apt-get -y upgrade

# Install GIT for accessing repositories, MC just for ease of use when connecting interactively
RUN apt-get -y install \
	git \
	mc

# Install SSH key for accessing GIT repositories
RUN mkdir /root/.ssh/
ADD keys/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa && \
    touch /root/.ssh/known_hosts && \
    ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Setting TERM to flawlessly run console applications like mc, nano when connecting interactively via docker exec
ENV TERM xterm
