#!/bin/sh
#
# This file updates the default VERSION build argument in the Dockerfile to the
# VERSION passed in to the file via environment variables.

set -evx

sed -i -r "s/^ARG VERSION=.+/ARG VERSION=${VERSION}/" Dockerfile
