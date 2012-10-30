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
  before :each do
    Chef::Config.stub!(:from_file).and_return(true)
  end

  it "configure knife from KNIFE_HOME env variable" do
    env_config = File.expand_path(File.join(Dir.tmpdir, 'knife.rb'))
    File.stub!(:exist?).and_return(false)
    File.stub!(:exist?).with(env_config).and_return(true)

    ENV['KNIFE_HOME'] = Dir.tmpdir
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == env_config
  end

   it "configure knife from PWD" do
    pwd_config = "#{Dir.pwd}/knife.rb"
    File.stub!(:exist?).and_return do | arg |
      [ pwd_config ].include? arg
    end

    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == pwd_config
  end
  
  it "configure knife from UPWARD" do
    upward_dir = File.expand_path "#{Dir.pwd}/.chef"
    upward_config = File.expand_path "#{upward_dir}/knife.rb"
    File.stub!(:exist?).and_return do | arg |
      [ upward_config ].include? arg
    end
    Chef::Knife.stub!(:chef_config_dir).and_return(upward_dir)
    
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == upward_config
  end
  
  it "configure knife from HOME" do
    home_config = File.expand_path(File.join("#{ENV['HOME']}", "/.chef/knife.rb"))
    File.stub!(:exist?).and_return do | arg |
      [ home_config ].include? arg
    end
    
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == home_config
  end
  
  it "configure knife from nothing" do
    ::File.stub!(:exist?).and_return(false)
    @knife = Chef::Knife.new
    @knife.ui.should_receive(:warn).with("No knife configuration file found")
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
    File.stub!(:exist?).and_return do | arg |
      configs.include? arg
    end
    Chef::Knife.stub!(:chef_config_dir).and_return(upward_dir)
    ENV['KNIFE_HOME'] = Dir.tmpdir
   
    @knife = Chef::Knife.new
    @knife.configure_chef
    @knife.config[:config_file].should == env_config
    
    configs.delete env_config
    @knife.config.delete :config_file
    @knife.configure_chef
    @knife.config[:config_file].should == pwd_config

    configs.delete pwd_config
    @knife.config.delete :config_file
    @knife.configure_chef
    @knife.config[:config_file].should == upward_config

    configs.delete upward_config
    @knife.config.delete :config_file
    @knife.configure_chef
    @knife.config[:config_file].should == home_config

    configs.delete home_config
    @knife.config.delete :config_file
    @knife.configure_chef
    @knife.config[:config_file].should be_nil
  end
end
