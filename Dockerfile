# About this Dockerfile:
# When run without any arguments passed, this Docker file will build the latest "stable" release of Chef. The version
# of that release is specified in the VERSION arg in this file, and is automatically updated as described below.
#
# Several processes occur using this file which are kicked off by our Expeditor pipeline tooling:
#
# When a build makes it through our internal CI system and is promoted to our "unstable" channel Expeditor will
# trigger a Docker image build of that version and push it to Docker Hub.
#
# When tests of an unstable build pass within our CI system it will be promoted to the "current" channel and
# Expeditor will tag that image as "current" on Docker Hub.
#
# When a build is promoted to our "stable" channel .expeditor/update_dockerfile.sh is run to update the version
# in this file and also tag that image as "latest" on Docker Hub. Additionally major and minor tags will be
# applied so 15.0.260 would be tagged as "latest", "15" and "15.0", as well as "15.0.260".

FROM busybox
LABEL maintainer="Chef Software, Inc. <docker@chef.io>"

ARG EXPEDITOR_CHANNEL
ARG CHANNEL=stable
ARG EXPEDITOR_VERSION
ARG VERSION=15.5.17

# Allow the build arg below to be controlled by either build arguments
ENV VERSION ${EXPEDITOR_VERSION:-${VERSION}}
ENV CHANNEL ${EXPEDITOR_CHANNEL:-${CHANNEL}}

RUN wget "http://packages.chef.io/files/${CHANNEL}/chef/${VERSION}/el/6/chef-${VERSION}-1.el6.x86_64.rpm" -O /tmp/chef-client.rpm && \
    rpm2cpio /tmp/chef-client.rpm | cpio -idmv && \
    rm -rf /tmp/chef-client.rpm

VOLUME [ "/opt/chef" ]
