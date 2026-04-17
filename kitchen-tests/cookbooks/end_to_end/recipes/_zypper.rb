#
# Cookbook:: end_to_end
# Recipe:: _zypper
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

# nginx.org only publishes x86_64 packages for SLES 15 (no aarch64).
# Guard the entire block so arm64 runners skip it cleanly.
if node["kernel"]["machine"] == "x86_64"
  zypper_repository "nginx repo" do
    baseurl "https://nginx.org/packages/sles/15"
    gpgkey "https://nginx.org/keys/nginx_signing.key"
  end

  # Pin to 1.26.3 because nginx.org builds >= 1.28 for SLES 15 are compiled
  # against OpenSSL 3.2+, but openSUSE Leap 15.x ships an older libssl that
  # does not provide the OPENSSL_3.2.0 symbol version, causing an
  # unresolvable dependency error at install time.
  zypper_package "nginx" do
    version "1.26.3"
  end

  # --------------------------------------------------------------------------
  # Option C – If the version-pin above breaks (e.g. nginx.org drops 1.26.x
  # from the SLES 15 repo), you can instead install a newer OpenSSL before
  # nginx.  Uncomment the block below and remove the version pin above.
  #
  # The openSUSE Leap 15 nginx.org package (>= 1.28) requires
  # libssl.so.3(OPENSSL_3.2.0)(64bit), which Leap 15.x does not provide by
  # default.  Installing openssl-3 (or libssl3) from a Leap backport / SLE
  # update repo satisfies the dependency, but may affect other packages that
  # assume the distro-default OpenSSL.  Test thoroughly before enabling.
  #
  # zypper_repository "suse-backports-update" do
  #   baseurl "https://download.opensuse.org/update/leap/15.6/backports/"
  #   gpgcheck false
  # end
  #
  # package "libopenssl3"
  #
  # zypper_package "nginx"   # no version pin needed once OpenSSL 3.2+ is present
  # --------------------------------------------------------------------------
end
