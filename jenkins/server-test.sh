#!/bin/bash

export LANG=en_US.UTF-8

set -e
set -x

echo "Attempting to remove ${project_name}, forcing success in case it's not installed"

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

usage()
{
  echo >&2 \
  "usage: $0 [-p project_name]"
}

# Get command line arguments
while getopts :p: opt
do
  echo $opt
  case "$opt" in
    p)  project_name="$OPTARG";;
    [\?]|[\:]) usage; exit 1;;
  esac
done

if [ -z $project_name ]
then
  usage
  exit 1
fi

if exists dpkg;
then
  sudo dpkg -P $project_name || true
  sudo jenkins/server-killer.sh
  sudo dpkg -i pkg/$project_name*deb
else
  sudo rpm -ev $project_name || true
  sudo jenkins/server-killer.sh
  sudo rpm -Uvh pkg/$project_name*rpm
fi

OMNIBUS_BIN = "$(printf "%s:" /opt/*/bin)"
OMNIBUS_EMBEDDED_BIN = "$(printf "%s:" /opt/*/embedded/bin)"
export PATH=$OMNIBUS_BIN:OMNIBUS_EMBEDDED_BIN:$PATH

sudo "${project_name}-ctl" reconfigure
sleep 120
sudo "${project_name}-ctl" test -J $WORKSPACE/pedant.xml --all

# when build succeeds, nuke the packages
find . -type d -maxdepth 1 -mindepth 1 | xargs rm -rf
