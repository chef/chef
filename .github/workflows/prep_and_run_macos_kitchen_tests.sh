## this somehow prevents ffi signature issues with macOS on kitchen tests
# related to https://github.com/ffi/ffi/issues/836 issue with code signature

cd kitchen-tests

sudo /opt/chef/embedded/bin/bundle config set --local without 'omnibus_package'
sudo /opt/chef/embedded/bin/bundle config set --local path 'vendor/bundle'
sudo /opt/chef/embedded/bin/bundle install --jobs=3 --retry=3
sudo rm -f /opt/chef/embedded/bin/{htmldiff,ldiff}

# gem installing berkshelf from rubygems picks up the newest ffi ~> 1.9
# match which conflicts with what's installed chef current. gem build and
# gem install from the cached gemspec appears to behave equivalent to bundler
# in using the ffi already installed (1.15.5 at the time of this writing) instead
# of installng the latest (1.16.3 at this moment)
# export BERKSHELF_GEMSPEC=$(find . -name 'berkshelf.gemspec')
# pushd $(dirname $BERKSHELF_GEMSPEC)
# sudo /opt/chef/embedded/bin/gem build berkshelf.gemspec

# export BERKSHELF_GEM=$(find . -name 'berkshelf*gem')
# sudo /opt/chef/embedded/bin/gem install $BERKSHELF_GEM --no-doc

# popd

# sudo /opt/chef/embedded/bin/berks vendor cookbooks
gem install berkshelf
sudo berks vendor cookbooks
sudo /opt/chef/bin/chef-client -z -o end_to_end --chef-license accept-no-persist
