FROM ubuntu:16.04
MAINTAINER Chef Software, Inc. <docker@chef.io>

ARG CHANNEL=stable
ARG VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/chef/bin:/opt/chef/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && \
    apt-get install -y wget ssh && \
    wget --content-disposition "https://omnitruck.chef.io/${CHANNEL}/chef/download?p=ubuntu&pv=16.04&m=x86_64&v=${VERSION}" -O /tmp/chef-client.deb && \
    dpkg -i /tmp/chef-client.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
