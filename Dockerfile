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
# applied so 15.0.260 would be tagged as "latest", "stable", "15" and "15.0", as well as "15.0.260".

FROM busybox
LABEL maintainer="Chef Software, Inc. <docker@chef.io>"

ARG CHANNEL=stable
ARG VERSION=17.10.114
ARG ARCH=x86_64
ARG PKG_VERSION=6

RUN wget "http://packages.chef.io/files/${CHANNEL}/chef/${VERSION}/el/${PKG_VERSION}/chef-${VERSION}-1.el${PKG_VERSION}.${ARCH}.rpm" -O /tmp/chef-client.rpm && \
    rpm2cpio /tmp/chef-client.rpm | cpio -idmv && \
    rm -rf /tmp/chef-client.rpm

VOLUME [ "/opt/chef" ]
