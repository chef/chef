gem update --system $(grep rubygems omnibus_overrides.rb | cut -d'"' -f2)
gem --version
gem uninstall bundler -a -x || true
gem install bundler -v $(grep :bundler omnibus_overrides.rb | cut -d'"' -f2)
bundle --version
rm -f .bundle/config
bundle install --without ci docgen guard integration maintenance omnibus_package --frozen
# force all .rspec tests into progress display to reduce line count
echo --color > .rspec
echo -fp >> .rspec
