# This script gets a container ready to run our various tests in BuildKite

# make sure we have the network tools in place for various network specs
if [ -f /etc/debian_version ]; then
  apt-get update -y && apt-get install -y net-tools iproute2
  touch /etc/network/interfaces
elif [ -f /etc/redhat-release ]; then
  yum install -y net-tools
fi

# make sure we have the omnibus_overrides specified version of rubygems / bundler
gem update --system $(grep rubygems omnibus_overrides.rb | cut -d'"' -f2)
gem --version
gem uninstall bundler -a -x || true
gem install bundler -v $(grep :bundler omnibus_overrides.rb | cut -d'"' -f2)
bundle --version
rm -f .bundle/config

# force all .rspec tests into progress display to reduce line count
echo --color > .rspec
echo -fp >> .rspec
