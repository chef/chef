#!/bin/sh
# WARNING: REQUIRES /bin/sh
#
# - must run on /bin/sh on solaris 9
# - must run on /bin/sh on AIX 6.x
# - if you think you are a bash wizard, you probably do not understand
#   this programming language.  do not touch.
# - if you are under 40, get peer review from your elders.

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
