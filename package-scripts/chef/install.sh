#!/bin/bash

#
# This chef-full install script is maintained @
# https://github.com/opscode/opscode-omnibus/tree/chef-full/package-scripts/chef-full/install.sh
#

release_version="0.10.8-4"
use_shell=0

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists() {
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

# Set the filename for a deb, based on version and machine
deb_filename() {
  filetype="deb"
  if [ $machine = "x86_64" ];
  then
    filename="chef-full_${version}_amd64.deb"
  else
    filename="chef-full_${version}_i386.deb"
  fi
}

# Set the filename for an rpm, based on version and machine
rpm_filename() {
  filetype="rpm"
  filename="chef-full-${version}.${machine}.rpm"
}

# Set the filename for a Solaris SVR4 package, based on version and machine
svr4_filename() {
  PATH=/usr/sfw/bin:$PATH
  filetype="solaris"
  filename="chef-full_${version}.${platform}.${platform_version}_${machine}.solaris"
}

# Set the filename for the sh archive
shell_filename() {
  filetype="sh"
  filename="chef-full-${version}-${platform}-${platform_version}-${machine}.sh"
}

report_bug() {
  echo "Please file a bug report at http://tickets.opscode.com"
  echo "Project: Chef"
  echo "Component: Packages"
  echo "Label: Omnibus"
  echo "Version: $release_version"
  echo " "
  echo "Please detail your operating system type, version and any other relevant details"
}

# Get command line arguments
while getopts sv: opt
do
  case "$opt" in
    v)  version="$OPTARG";;
    s)  use_shell=1;;
    \?)   # unknown flag
      echo >&2 \
      "usage: $0 [-s] [-v version]"
      exit 1;;
  esac
done
shift `expr $OPTIND - 1`

machine=$(echo -e `uname -m`)

# Retrieve Platform and Platform Version
if [ -f "/etc/lsb-release" ];
then
  platform=$(grep DISTRIB_ID /etc/lsb-release | cut -d "=" -f 2 | tr '[A-Z]' '[a-z]')
  platform_version=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f 2)
elif [ -f "/etc/debian_version" ];
then
  platform="debian"
  platform_version=$(echo -e `cat /etc/debian_version`)
elif [ -f "/etc/redhat-release" ];
then
  platform=$(sed 's/^\(.\+\) release.*/\1/' /etc/redhat-release | tr '[A-Z]' '[a-z]')
  platform_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release)

  # If /etc/redhat-release exists, we act like RHEL by default
  if [ "$platform" = "fedora" ];
  then
    # Change platform version for use below.
    platform_version="6.0"
  fi
  platform="el"
elif [ -f "/etc/system-release" ];
then
  platform=$(sed 's/^\(.\+\) release.\+/\1/' /etc/system-release | tr '[A-Z]' '[a-z]')
  platform_version=$(sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/system-release | tr '[A-Z]' '[a-z]')
  # amazon is built off of fedora, so act like RHEL
  if [ "$platform" = "amazon linux ami" ];
  then
    platform="el"
    platform_version="6.0"
  fi
# Apple OS X
elif [ -f "/usr/bin/sw_vers" ];
then
  platform="mac_os_x"
  # Matching the tab-space with sed is error-prone
  platform_version=$(sw_vers | awk '/^ProductVersion:/ { print $2 }')

  major_version=$(echo $platform_version | cut -d. -f1,2)
  case $major_version in
    "10.6") platform_version="10.6.8" ;;
    "10.7") platform_version="10.7.2" ;;
    *) echo "No builds for platform: $major_version"
       report_bug
       exit 1
       ;;
  esac

  # x86_64 Apple hardware often runs 32-bit kernels (see OHAI-63)
  x86_64=$(sysctl -n hw.optional.x86_64)
  if [ $x86_64 -eq 1 ]; then
    machine="x86_64"
  fi
elif [ -f "/etc/release" ];
then
  platform="solaris2"
  machine=$(/usr/bin/uname -p)
  platform_version=$(/usr/bin/uname -r)
fi

if [ "x$platform" = "x" ];
then
  echo "Unable to determine platform!"
  report_bug
  exit 1
fi

# Mangle $platform_version to pull the correct build
# for various platforms
major_version=$(echo $platform_version | cut -d. -f1)
case $platform in
  "el")
    case $major_version in
      "5") platform_version="5.7" ;;
      "6") platform_version="6.2" ;;
    esac
    ;;
  "debian")
    case $major_version in
      "5") platform_version="6.0.1";;
      "6") platform_version="6.0.1";;
    esac
    ;;
  "ubuntu")
    case $platform_version in
      "10.10") platform_version="10.04";;
      "11.10") platform_version="11.04";;
      "12.04") platform_version="11.04";;
    esac
    ;;
esac

if [ "x$platform_version" = "x" ];
then
  echo "Unable to determine platform version!"
  report_bug
  exit 1
fi

if [ -z "$version" ];
then
    version=$release_version
fi

if [ $use_shell = 1 ];
then
  shell_filename
else
  case $platform in
    "ubuntu") deb_filename ;;
    "debian") deb_filename ;;
    "el") rpm_filename ;;
    "fedora") rpm_filename ;;
    "solaris2") svr4_filename ;;
    *) shell_filename ;;
  esac
fi

echo "Downloading Chef $version for ${platform}..."

url="http://s3.amazonaws.com/opscode-full-stack/$platform-$platform_version-$machine/$filename"

if exists wget;
then
  downloader="wget"
  wget -O /tmp/$filename $url 2>/tmp/stderr
elif exists curl;
then
  downloader="curl"
  curl $url > /tmp/$filename
else
  echo "Cannot find wget or curl - cannot install Chef!"
  exit 5
fi

# Check to see if we got a 404 or an empty file

unable_to_retrieve_package() {
  echo "Unable to retrieve a valid package!"
  report_bug
  echo "URL: $url"
  exit 1
}

if [ $downloader == "curl" ]
then 
  #do curl stuff
  grep "The specified key does not exist." /tmp/$filename 2>&1 >/dev/null
  if [ $? -eq 0 ] || [ ! -s /tmp/$filename ] 
  then
    unable_to_retrieve_package
  fi
elif [ $downloader == "wget" ]
then
  #do wget stuff
  grep "ERROR 404" /tmp/stderr 2>&1 >/dev/null
  if [ $? -eq 0 ] || [ ! -s /tmp/$filename ] 
  then
    unable_to_retrieve_package
  fi
fi

echo "Installing Chef $version"
case "$filetype" in
  "rpm") rpm -Uvh /tmp/$filename ;;
  "deb") dpkg -i /tmp/$filename ;;
  "solaris") echo "conflict=nocheck" > /tmp/nocheck
             echo "action=nocheck" >> /tmp/nocheck
             pkgadd -a /tmp/nocheck -G -d /tmp/$filename all
 	     ;;
  "sh" ) bash /tmp/$filename ;;
esac

if [ $? -ne 0 ];
then
  echo "Installation failed"
  report_bug
  exit 1
fi
