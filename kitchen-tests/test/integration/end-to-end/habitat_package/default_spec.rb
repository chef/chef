describe user('hab') do
  it { should exist }
end

describe file('/bin/hab') do
  it { should exist }
  it { should be_symlink }
end

# This needs to be updated each time Habitat is released so we ensure we're getting the version
# required by this cookbook.
describe command('hab -V') do
  its('stdout') { should match(%r{^hab.*/}) }
  its('exit_status') { should eq 0 }
end

describe directory('/hab/pkgs/core/redis') do
  it { should exist }
end

describe command('hab pkg path core/redis') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(%r{/hab/pkgs/core/redis}) }
end

describe directory('/hab/pkgs/lamont-granquist/ruby/2.3.1') do
  it { should exist }
end

describe command('hab pkg path lamont-granquist/ruby/2.3.1') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(%r{/hab/pkgs/lamont-granquist/ruby/2.3.1}) }
end

describe directory('/hab/pkgs/core/bundler/1.13.3/20161011123917') do
  it { should exist }
end

describe command('hab pkg path core/bundler/1.13.3/20161011123917') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(%r{/hab/pkgs/core/bundler/1.13.3/20161011123917}) }
end

describe file('/bin/htop') do
  it { should be_symlink }
  its(:link_path) { should match(%r{/hab/pkgs/core/htop}) }
end

describe file('/bin/nginx') do
  it { should_not exist }
end
