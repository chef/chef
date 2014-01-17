source "https://rubygems.org"
gemspec :name => "chef"

gem "activesupport", "< 4.0.0", :group => :compat_testing, :platform => "ruby"

# Remove this line before shipping Chef version for Ohai 7.0 Release Candidate.
gem "ohai", :git => "https://github.com/opscode/ohai.git"

group(:docgen) do
  gem "ronn"
  gem "yard"
end

group(:development, :test) do
  gem "simplecov"
  gem 'rack', "~> 1.5.1"

  gem 'ruby-shadow', :platforms => :ruby unless RUBY_PLATFORM.downcase.match(/(darwin|freebsd|aix)/)
end

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
