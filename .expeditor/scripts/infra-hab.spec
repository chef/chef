# Disable any shell actions, replace them with simply 'true'
%define __spec_prep_post true
%define __spec_prep_pre true
%define __spec_build_post true
%define __spec_build_pre true
%define __spec_install_post true
%define __spec_install_pre true
%define __spec_clean_post true
%define __spec_clean_pre true

# Use SHA256 checksums for all files
%define _binary_filedigest_algorithm 8

%define _binary_payload w1.xzdio

# Disable creation of build-id links
%define _build_id_links none

# Metadata
Name: chef
Version: %{VERSION}~%{RELEASE}
Release: 1%{?dist}
Summary:  The full stack of chef
AutoReqProv: no
BuildRoot: %buildroot
Prefix: /
Group: default
License: Chef EULA
Vendor: Progress Software Inc.
URL: https://www.chef.io
Packager: Chef Software, Inc. <maintainers@chef.io>
%description
The full stack of chef

%prep
# noop

%build
# noop

%install
# noop

%clean
# noop

%pre
# noop

%post
#!/bin/sh
# WARNING: REQUIRES /bin/sh
#
# - must run on /bin/sh on solaris 9
# - must run on /bin/sh on AIX 6.x
# - this file is sh not bash so do not introduce bash-isms
# - if you are under 40, get peer review from your elders.
#
# Install Chef Infra Client
#
INSTALLER_DIR="/hab/chef/%{VERSION}/%{RELEASE}"

# extract the components into /hab (will expand into hab/pkg).
pushd /hab
tar --strip-components=1 -xf /hab/chef-chef-infra-client-%{VERSION}-%{RELEASE}.tar.gz
popd

# Create wrapper binaries
mkdir -p $INSTALLER_DIR/bin
binaries=("chef-apply" "chef-client" "chef-resource-inspector" "chef-service-manager" "chef-shell" "chef-solo" "chef-windows-service" "inspec" "ohai")
for binary in "${binaries[@]}"; do
  cat << EOF > $INSTALLER_DIR/bin/$binary
#!/bin/sh
/hab/bin/hab pkg exec chef/chef-infra-client/%{VERSION}/%{RELEASE} $binary -- "\$@"
EOF
  chmod +x $INSTALLER_DIR/bin/$binary
done

PROGNAME=`basename $0`
CONFIG_DIR=/etc/chef
USAGE="usage: $0 [-v validation_key] ([-o organization] || [-u url])"

error_exit()
{
  echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
  exit 1
}

is_darwin()
{
  uname -a | grep "^Darwin" 2>&1 >/dev/null
}

if is_darwin; then
    PREFIX="/usr/local"
    mkdir -p "$PREFIX/bin"
else
    PREFIX="/usr"
fi

validation_key=
organization=
chef_url=

while getopts o:u:v: opt
do
    case "$opt" in
      v)  validation_key="${OPTARG}";;
      o)  organization="${OPTARG}"; chef_url="https://api.opscode.com/organizations/${OPTARG}";;
      u)  chef_url="${OPTARG}";;
      \?)    # unknown flag
          echo >&2 ${USAGE}
    exit 1;;
    esac
done
shift `expr ${OPTIND} - 1`

if [ "" != "$chef_url" ]; then
  mkdir -p ${CONFIG_DIR} || error_exit "Cannot create ${CONFIG_DIR}!"
  (
  cat <<'EOP'
log_level :info
log_location STDOUT
EOP
  ) > ${CONFIG_DIR}/client.rb
  if [ "" != "$chef_url" ]; then
    echo "chef_server_url '${chef_url}'" >> ${CONFIG_DIR}/client.rb
  fi
  if [ "" != "$organization" ]; then
    echo "validation_client_name '${organization}-validator'" >> ${CONFIG_DIR}/client.rb
  fi
  chmod 640 ${CONFIG_DIR}/client.rb
fi

if [ "" != "$validation_key" ]; then
  cp ${validation_key} ${CONFIG_DIR}/validation.pem || error_exit "Cannot copy the validation key!"
  chmod 600 ${CONFIG_DIR}/validation.pem
fi

# rm -f before ln -sf is required for solaris 9
rm -f $PREFIX/bin/chef-client
rm -f $PREFIX/bin/chef-solo
rm -f $PREFIX/bin/chef-apply
rm -f $PREFIX/bin/chef-shell
rm -f $PREFIX/bin/knife
rm -f $PREFIX/bin/ohai

ln -sf $INSTALLER_DIR/bin/chef-solo $PREFIX/bin || error_exit "Cannot link chef-solo to $PREFIX/bin"
if [ -f "$INSTALLER_DIR/bin/chef-apply" ]; then
  ln -sf $INSTALLER_DIR/bin/chef-apply $PREFIX/bin || error_exit "Cannot link chef-apply to $PREFIX/bin"
fi
if [ -f "$INSTALLER_DIR/bin/chef-shell" ]; then
  ln -sf $INSTALLER_DIR/bin/chef-shell $PREFIX/bin || error_exit "Cannot link chef-shell to $PREFIX/bin"
fi
ln -sf $INSTALLER_DIR/bin/ohai $PREFIX/bin || error_exit "Cannot link ohai to $PREFIX/bin"

# We test for the presence of /usr/bin/chef-client to know if this script succeeds, so this
# must appear as the last real action in the script
ln -sf $INSTALLER_DIR/bin/chef-client $PREFIX/bin || error_exit "Cannot link chef-client to $PREFIX/bin"

# make the base structure for chef to run
# the sample client.rb is only written out of no chef config dir exists yet
if ! [ -d $CONFIG_DIR ]; then
   mkdir -p $CONFIG_DIR
   cat >"$CONFIG_DIR/client.rb" <<EOF
# The client.rb file specifies how Chef Infra Client is configured on a node
# See https://docs.chef.io/config_rb_client/ for detailed configuration options
#
# Minimal example configuration:
# node_name  "THIS_NODE_NAME"
# chef_server_url  "https://CHEF.MYCOMPANY.COM/organizations/MY_CHEF_ORG"
# chef_license  "accept"
EOF
fi

mkdir -p "$CONFIG_DIR/client.d"
mkdir -p "$CONFIG_DIR/accepted_licenses"
mkdir -p "$CONFIG_DIR/trusted_certs"
mkdir -p "$CONFIG_DIR/ohai/plugins"

echo "Thank you for installing Chef Infra Client! For help getting started visit https://learn.chef.io"

exit 0

%postun
#!/bin/sh
# WARNING: REQUIRES /bin/sh
#
# - must run on /bin/sh on solaris 9
# - must run on /bin/sh on AIX 6.x
# - if you think you are a bash wizard, you probably do not understand
#   this programming language.  do not touch.
# - if you are under 40, get peer review from your elders.

INSTALLER_DIR="/hab/chef/%{VERSION}/%{RELEASE}"

is_darwin() {
  uname -a | grep "^Darwin" 2>&1 >/dev/null
}

is_suse() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    [ "$ID_LIKE" = "sles" ] || [ "$ID_LIKE" = "suse" ]
  else
    [ -f /etc/SuSE-release ]
  fi
}

if is_darwin; then
    PREFIX="/usr/local"
else
    PREFIX="/usr"
fi

cleanup_symlinks() {
  binaries="chef-client chef-solo chef-apply chef-shell knife ohai"
  for binary in $binaries; do
    rm -f $PREFIX/bin/$binary
  done
}

# Clean up binary symlinks if they exist
# see: http://tickets.opscode.com/browse/CHEF-3022
if [ ! -f /etc/redhat-release -a ! -f /etc/fedora-release -a ! -f /etc/system-release -a ! is_suse ]; then
  # not a redhat-ish RPM-based system
  cleanup_symlinks
elif [ "x$1" = "x0" ]; then
  # RPM-based system and we're uninstalling rather than upgrading
  cleanup_symlinks
fi

rm -rf $INSTALLER_DIR || true


# Even though it's safe and cleaner, we can't do it this way.
# The /hab/accepted-licenses directory will be gone and hab will fail because there's no accepted license.
# Even if we put this in `%preun`, we'll see the same thing if no chef command was ever run and so the hab
# license was never accepted.
# /hab/bin/hab pkg uninstall chef/chef-infra-client/%{VERSION}/%{RELEASE} || true

# Instead we'll do what we safely can directly:
rm -rf /hab/pkgs/chef/chef-infra-client/%{VERSION}/%{RELEASE} || true

# Remove /hab if it is empty after this RPM is uninstalled
# TODO - this directory will never be empty, because there are other components (inlcuding /hab/bin/hab itself)
#        included in the tarball that we can't safely erase . This means we'll /always/ leave something behind
#        in /hab, unless we verify that no other non-infra components are installed and remove everything.
if [ -d /hab ] && [ -z "$(ls -A /hab)" ]; then
  rmdir /hab
fi

%files
%defattr(-,root,root,-)
%dir %attr(0755,root,root) /hab
