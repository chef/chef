## this somehow prevents ffi signature issues with macOS on kitchen tests
sudo /opt/chef/embedded/bin/bundle config set --local without 'omnibus_package'
sudo /opt/chef/embedded/bin/bundle config set --local path 'vendor/bundle'
sudo /opt/chef/embedded/bin/bundle install --jobs=3 --retry=3
sudo rm -f /opt/chef/embedded/bin/{htmldiff,ldiff}

export BERKSHELF_GEMSPEC=$(find . -name 'berkshelf.gemspec')
pushd $(dirname $BERKSHELF_GEMSPEC)
sudo /opt/chef/embedded/bin/gem build berkshelf.gemspec

export BERKSHELF_GEM=$(find . -name 'berkshelf*gem')
sudo /opt/chef/embedded/bin/gem install $BERKSHELF_GEM --no-doc

popd

sudo /opt/chef/embedded/bin/berks vendor cookbooks
sudo /opt/chef/bin/chef-client -z -o end_to_end --chef-license accept-no-persist
