FROM busybox
LABEL maintainer="Chef Software, Inc. <docker@chef.io>"

ARG EXPEDITOR_CHANNEL
ARG CHANNEL=stable
ARG EXPEDITOR_VERSION
ARG VERSION=14.15.6

# Allow the build arg below to be controlled by either build arguments
ENV VERSION ${EXPEDITOR_VERSION:-${VERSION}}
ENV CHANNEL ${EXPEDITOR_CHANNEL:-${CHANNEL}}

RUN wget "http://packages.chef.io/files/${CHANNEL}/chef/${VERSION}/el/6/chef-${VERSION}-1.el6.x86_64.rpm" -O /tmp/chef-client.rpm && \
    rpm2cpio /tmp/chef-client.rpm | cpio -idmv && \
    rm -rf /tmp/chef-client.rpm

VOLUME [ "/opt/chef" ]
