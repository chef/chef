#!/bin/bash
set -ueox pipefail
zypper addrepo --check --priority 50 --refresh --name "Chefzypper-repo" "https://mirror.fcix.net/opensuse/distribution/leap/15.3/repo/oss/" "chefzypper"
zypper install -y cron insserv-compat libarchive-devel