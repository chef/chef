require 'spec_helper'

# Ported from https://github.com/chef/omnibus-chef/blob/master/jenkins/verify-chef.sh

describe 'chef-verify' do
  describe file('/usr/bin/chef-client') do
    it { should be_symlink }
  end

  describe file('/usr/bin/knife') do
    it { should be_symlink }
  end

  describe file('/usr/bin/chef-solo') do
    it { should be_symlink }
  end

  describe file('/usr/bin/ohai') do
    it { should be_symlink }
  end

  describe command('chef-client --version') do
    its(:exit_status) { should eq 0 }
  end

  describe command("/opt/chef/embedded/bin/ruby --version") do
    its(:exit_status) { should eq 0 }
  end

  describe command("/opt/chef/embedded/bin/gem --version") do
    its(:exit_status) { should eq 0 }
  end

  describe command("/opt/chef/embedded/bin/bundle --version") do
    its(:exit_status) { should eq 0 }
  end

  describe command("/opt/chef/embedded/bin/rspec --version") do
    its(:exit_status) { should eq 0 }
  end
end
