set -x
sudo /opt/chef/embedded/bin/bundle config set --local without 'omnibus_package'
sudo /opt/chef/embedded/bin/bundle config set --local path 'vendor/bundle'
sudo /opt/chef/embedded/bin/bundle install --jobs=3 --retry=3
sudo rm -f /opt/chef/embedded/bin/{htmldiff,ldiff}
sudo /opt/chef/embedded/bin/gem build $(find . -name berkshelf.gemspec)
sudo /opt/chef/embedded/bin/gem install $(find . -name 'berkshelf*.gem')
# sudo /opt/chef/embedded/bin/gem install berkshelf --no-doc
sudo /opt/chef/embedded/bin/berks vendor cookbooks
sudo /opt/chef/bin/chef-client -z -o end_to_end --chef-license accept-no-persist
