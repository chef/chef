#!/bin/bash

CHEF_FOUNDATION_VERSION=$(cat .buildkite-platform.json | jq -r '.chef_foundation')
export CHEF_FOUNDATION_VERSION
echo "Chef Foundation Version: $CHEF_FOUNDATION_VERSION"
