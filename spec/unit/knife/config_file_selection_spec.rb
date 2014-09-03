#
# Author:: Nicolas Vinot (<aeris@imirhil.fr>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'tmpdir'

describe Chef::Knife do

  let(:missing_config_fetcher) do
    double(Chef::ConfigFetcher, :config_missing? => true)
  end

  let(:available_config_fetcher) do
    double(Chef::ConfigFetcher, :config_missing? => false,
                                :read_config => "")
  end

  def have_config_file(path)
    Chef::ConfigFetcher.should_receive(:new).at_least(1).times.with(path, nil).and_return(available_config_fetcher)
  end

  before do
    # Make sure tests can run when HOME is not set...
    @original_home = ENV["HOME"]
    ENV["HOME"] = Dir.tmpdir
  end

  after do
    ENV["HOME"] = @original_home
  end

  before :each do
    Chef::Config.stub(:from_file).and_return(true)
    Chef::ConfigFetcher.stub(:new).and_return(missing_config_fetcher)
  end

  it "configure knife from KNIFE_HOME env variable" do
    env_config = File.expand_path(File.join(Dir.tmpdir, 'knife.rb'))
    have_config_file(env_config)

    ENV['KNIFE_HOME'] = Dir.tmpdir
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == env_config
  end

   it "configure knife from PWD" do
    pwd_config = "#{Dir.pwd}/knife.rb"
    have_config_file(pwd_config)

    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == pwd_config
  end

  it "configure knife from UPWARD" do
    upward_dir = File.expand_path "#{Dir.pwd}/.chef"
    upward_config = File.expand_path "#{upward_dir}/knife.rb"
    have_config_file(upward_config)
    Chef::Knife.stub(:chef_config_dir).and_return(upward_dir)

    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == upward_config
  end

  it "configure knife from HOME" do
    home_config = File.expand_path(File.join("#{ENV['HOME']}", "/.chef/knife.rb"))
    have_config_file(home_config)

    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == home_config
  end

  it "configure knife from nothing" do
    ::File.stub(:exist?).and_return(false)
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should be_nil
  end

  it "configure knife precedence" do
    env_config = File.join(Dir.tmpdir, 'knife.rb')
    pwd_config = "#{Dir.pwd}/knife.rb"
    upward_dir = File.expand_path "#{Dir.pwd}/.chef"
    upward_config = File.expand_path "#{upward_dir}/knife.rb"
    home_config = File.expand_path(File.join("#{ENV['HOME']}", "/.chef/knife.rb"))
    configs = [ env_config, pwd_config, upward_config, home_config ]

    Chef::Knife.stub(:chef_config_dir).and_return(upward_dir)
    ENV['KNIFE_HOME'] = Dir.tmpdir

    @knife = Chef::Knife.new

    @knife.configure_chef
    @knife.config[:config_file].should be_nil

    have_config_file(home_config)
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == home_config

    have_config_file(upward_config)
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == upward_config

    have_config_file(pwd_config)
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == pwd_config

    have_config_file(env_config)
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == env_config
  end
end
