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

Name:           chef-infra-client
Version:        %{VERSION}
Release:        1%{?dist}
Summary:        The full stack of Chef Infra Client
AutoReqProv: 	no
BuildRoot: 	    %buildroot
Prefix: 	    /
Group: 		    default
License:        Chef EULA
URL: 		    https://www.chef.io
Packager: 	    Chef Software, Inc. <maintainers@chef.io>
Source0:        %{CHEF_INFRA_TAR}
Source1:        %{CHEF_MIGRATE_TAR}

%description
The full stack of Chef Infra Client

%prep
# noop

%build
# noop

%install
# Create the installation directory for the migration tools
#mkdir -p %{buildroot}/opt/chef
mkdir -p %{buildroot}/opt/chef/{bin,bundle}

# Untar the migration tools into /opt/chef/bin
tar -xf %{SOURCE1} -C %{buildroot}/opt/chef/bin

# Copy the chef infra tarball into /opt/chef/bundle
cp %{SOURCE0} %{buildroot}/opt/chef/bundle/

%files
/opt/chef
/opt/chef/bin
/opt/chef/bin/*
/opt/chef/bundle
/opt/chef/bundle/*

%post

# Determine if --fresh_install needs to be passed based on the existence of the /opt/chef directory
MIGRATE_CMD="/opt/chef/bin/chef-migrate apply airgap"
if [ ! -d /opt/chef ]; then
    MIGRATE_CMD="$MIGRATE_CMD --fresh_install"
fi

# Check for CHEF_INFRA_LICENSE_KEY and CHEF_INFRA_LICENSE_SERVER environment variables
if [ -n "$CHEF_INFRA_LICENSE_KEY" ]; then
    MIGRATE_CMD="$MIGRATE_CMD --license.key $CHEF_INFRA_LICENSE_KEY"
fi

if [ -n "$CHEF_INFRA_LICENSE_SERVER" ]; then
    MIGRATE_CMD="$MIGRATE_CMD --license.server $CHEF_INFRA_LICENSE_SERVER"
fi

# Add the tarball path
MIGRATE_CMD="$MIGRATE_CMD /opt/chef/bundle/%{CHEF_INFRA_TAR}"

# Invoke the chef-migrate tool using the tarball as input
if [ -f /opt/chef//bin/chef-migrate ]; then
    eval $MIGRATE_CMD
else
    echo "Error: chef-migrate tool not found in /opt/chef/bin"
    exit 1
fi

%changelog
# Nothing yet!
