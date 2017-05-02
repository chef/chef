FROM busybox
MAINTAINER Chef Software, Inc. <docker@chef.io>

ARG CHANNEL=stable
ARG VERSION=12.20.3

RUN wget "http://packages.chef.io/files/${CHANNEL}/chef/${VERSION}/el/5/chef-${VERSION}-1.el5.x86_64.rpm" -O /tmp/chef-client.rpm && \
    rpm2cpio /tmp/chef-client.rpm | cpio -idmv && \
    rm -rf /tmp/chef-client.rpm

VOLUME [ "/opt/chef" ]
