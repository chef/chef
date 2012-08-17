#!/bin/bash
#
# Test you some omnibus client
#
set -e
set -x

# Check whether a command exists - returns 0 if it does, 1 if it does not
exists()
{
  if command -v $1 &>/dev/null
  then
    return 0
  else
    return 1
  fi
}

# remove the chef package / clobber the files
# then install the new package
if exists dpkg;
then
    sudo dpkg -P chef || true
    sudo rm -rf /opt/chef/*
    sudo dpkg -i pkg/chef*.deb
elif exists rpm;
then
    sudo rpm -ev chef || true
    sudo rm -rf /opt/chef/*
    sudo rpm -Uvh pkg/chef*.rpm
elif exists pkgadd;
then
    cat <<EOF > /tmp/nocheck
conflict=nocheck
action=nocheck
EOF
    sudo pkgrm -a /tmp/nocheck -n chef || true
    # BUGBUG: we have to do this twice because the postrm fails the first time
    sudo pkgrm -a /tmp/nocheck -n chef || true
    sudo rm -rf /opt/chef/*
    # BUGBUG: we don't remove symlinks correctly so the install fails the next time
    sudo pkgadd -n -d pkg/chef*.solaris -a /tmp/nocheck chef || true
else # makeself installer
    sudo rm  -rf /opt/chef/*
    # BUGBUG: without an uninstaller the makeself installer fails when creating symlinks
    sudo ./pkg/chef*.sh || true
fi

# extract the chef source code
mkdir -p src/chef
gzip -dc src/chef*.tar.gz | (tar -C src/chef -xf -)

# install all of the development gems
cd src/chef/chef
mkdir bundle
export PATH=/opt/chef/bin:/opt/chef/embedded/bin:$PATH
bundle config build.eventmachine --with-cflags=-fpermissive

# bundle install may fail if the internets are down
retries=0
while true; do
  if bundle install --without server --path bundle; then
    break
  fi
  retries=$( expr $retries + 1 )
  if [ $retries -ge 10 ]; then
    echo "bundle install failed after 10 retries"
    exit 1
  fi
  echo "retrying bundle install"
done

# run the tests
sudo env PATH=$PATH bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec
