#!/bin/bash

VERSION_STRING=$(cat /etc/os-release | grep '^VERSION=' | sed 's/VERSION=\"\([0-9]\+\).*/\1/')
if [[ $VERSION_STRING == "15" ]]
then
  echo "--- :hammer_and_wrench: Updating Zypper Repos on openSUSE 15"
  find /etc/zypp/repos.d -name "SMT-*" -execdir rm -f -- '{}' \;
  zypper addrepo --check --priority 50 --refresh --name "Chefzypper-repo" "https://mirror.fcix.net/opensuse/distribution/leap/15.3/repo/oss/" "chefzypper"
  zypper --gpg-auto-import-keys ref
  zypper refresh
  zypper in -t patch SUSE-SLE-Module-Basesystem-15-SPx-202x-2224=1
else
  echo "--- :hammer_and_wrench: Not Running on openSUSE 15, nothing to do"
fi
