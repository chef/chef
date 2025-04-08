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
ARG VERSION=19.0.49
ARG ARCH=x86_64
ARG PKG_VERSION=6
ARG INFRA_PACKAGE="chef/chef-infra-client"

ARG HAB_CHANNEL=stable
ARG HAB_VERSION="1.6.1041"
ARG HABITAT_PACKAGE="core/hab/1.6.1041"

ADD https://packages.chef.io/files/${HAB_CHANNEL}/habitat/${HAB_VERSION}/hab-x86_64-linux.tar.gz /tmp/hab.tar.gz

RUN mkdir /tmp/hab
RUN mkdir /hab
RUN tar -xzf /tmp/hab.tar.gz -C /tmp/hab && \
    cd /tmp/hab && \
    HAB_DIR=$(find . -type d -name "hab-*") && \
    cp $HAB_DIR/hab /hab/hab

ENV HAB_LICENSE="accept-no-persist"
RUN /hab/hab pkg install --binlink --force --channel "${CHANNEL}" "${HABITAT_PACKAGE}"
RUN rm /tmp/hab.tar.gz
RUN rm -rf /tmp/hab

RUN hab pkg install --channel "${CHANNEL}" "core/bash"
RUN TMP=$(hab pkg path core/bash) && ln -s "${TMP}/bin/bash" /bin/bash

RUN hab pkg install --binlink --force --channel "${CHANNEL}" "${INFRA_PACKAGE}/${VERSION}"

VOLUME [ "/hab" ]
