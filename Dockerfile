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
LABEL maintainer="Progress Chef <docker@chef.io>"

#TODO: Change back to stable when 19.x is GA
ARG CHANNEL=unstable
ARG VERSION=19.1.164
ARG ARCH=x86_64

ENV HAB_LICENSE="accept-no-persist"

# Use --mount=type=secret to access HAB_AUTH_TOKEN securely
RUN --mount=type=secret,id=hab_token \
    wget -qO /tmp/hab.tar.gz https://packages.chef.io/files/stable/habitat/latest/hab-${ARCH}-linux.tar.gz && \
    mkdir /tmp/hab && \
    tar -xzf /tmp/hab.tar.gz -C /tmp/hab && \
    HAB_DIR=$(find /tmp/hab -type d -name "hab-*") && \
    $HAB_DIR/hab pkg install --binlink --force --channel "stable" "core/hab" && \
    rm -rf /tmp/* && \
    HAB_AUTH_TOKEN=$(cat /run/secrets/hab_token) hab pkg install --binlink --force --auth "$(cat /run/secrets/hab_token)" --channel "${CHANNEL}" "chef/chef-infra-client/${VERSION}" && \
    rm -rf /hab/cache

VOLUME [ "/hab" ]
