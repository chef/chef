#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Application, "initialize" do
  before do
    @app = Chef::Application.new
  end
  
  it "should create an instance of Chef::Application" do
    @app.should be_kind_of(Chef::Application)
  end
end

  
describe Chef::Application, "reconfigure" do
  before do
    @app = Chef::Application.new
  end
  
  it "should configure the options parser" do
    @app.should_receive(:configure_opt_parser).and_return(true)
    @app.reconfigure
  end
  
  it "should configure chef" do
    @app.should_receive(:configure_chef).and_return(true)
    @app.reconfigure
  end
      
  it "should configure logging" do
    @app.should_receive(:configure_logging).and_return(true)
    @app.reconfigure  
  end
  
end
  
describe Chef::Application do
  before do
    @app = Chef::Application.new
  end
  
  describe "run" do
    before do
      @app.stub!(:setup_application).and_return(true)
      @app.stub!(:run_application).and_return(true)
    end
    
    it "should reconfigure the application before running" do
      @app.should_receive(:reconfigure).and_return(true)
      @app.run
    end
    
    it "should setup the application before running it" do
      @app.should_receive(:setup_application).and_return(true)
      @app.run
    end
    
    it "should run the actual application" do
      @app.should_receive(:run_application).and_return(true)
      @app.run
    end
  end
end

describe Chef::Application, "configure_opt_parser" do
  before do
    @opt = mock("OptionParser", :null_object => true)
    @opt.stub!(:parse!).and_return(true)
    OptionParser.stub!(:new).and_yield(@opt)
    @app = Chef::Application.new
  end

  it "should create a new OptionParser" do
    OptionParser.should_receive(:new).and_yield(@opt)
    @app.configure_opt_parser
  end
    
  { :config_file => {
      :short => "-c CONFIG",
      :long => "--config CONFIG",
      :description => "The Chef Config file to use",
      :proc => nil }, 
    :log_level => { 
      :short => "-l LEVEL",
      :long => "--loglevel LEVEL",
      :description => "Set the log level (debug, info, warn, error, fatal)",
      :proc => lambda { |p| p.to_sym} },
    :log_location => {
      :short => "-L LOGLOCATION",
      :long => "--logfile LOGLOCATION",
      :description => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
      :proc => nil }
  }.each do |opt_key, opt_val|
    # Can't seem to work out how to make this check the 'proc' option, so just short/long/desc for now.
    %w{short long description}.collect { |s| s.to_sym }.each do |opt|
      it "should have the default option #{opt_key} with the #{opt.to_s} value of #{opt_val[opt].to_s}" do
        @app.configure_opt_parser
        @app.options[opt_key][opt].should == opt_val[opt]
      end
    end
  end
  
  describe "with additional options" do
    before do
      @app.options = {
        :banana_boat => {
          :short => "-b BANANABOAT",
          :long => "--bananaboat BANANABOAT",
          :description => "I see a deadly black tarantula!",
          :proc => nil }
        }
    end
    
    { :config_file => {
        :short => "-c CONFIG",
        :long => "--config CONFIG",
        :description => "The Chef Config file to use",
        :proc => nil }, 
      :log_level => { 
        :short => "-l LEVEL",
        :long => "--loglevel LEVEL",
        :description => "Set the log level (debug, info, warn, error, fatal)",
        :proc => lambda { |p| p.to_sym} },
      :log_location => {
        :short => "-L LOGLOCATION",
        :long => "--logfile LOGLOCATION",
        :description => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
        :proc => nil },
      :banana_boat => {
        :short => "-b BANANABOAT",
        :long => "--bananaboat BANANABOAT",
        :description => "I see a deadly black tarantula!",
        :proc => nil }
    }.each do |opt_key, opt_val|
      # Can't seem to work out how to make this check the 'proc' option, so just short/long/desc for now.
      %w{short long description}.collect { |s| s.to_sym }.each do |opt|
        it "should have the option #{opt_key} with the #{opt.to_s} value of #{opt_val[opt].to_s}" do
          @app.configure_opt_parser
          @app.options[opt_key][opt].should == opt_val[opt]
        end
      end
    end
    
  end
end

describe Chef::Application, "configure_chef" do
  before do
    @app = Chef::Application.new
  end
  
  describe "when a config_file is present" do
    before do
      @app.config[:config_file] = "/etc/chef/default.rb"
    end
    
    it "should configure chef::config from a file" do
      Chef::Config.should_receive(:from_file).with("/etc/chef/default.rb")
      @app.configure_chef
    end
  end
  
  describe "when there is no config_file defined" do
    before do
      @app.config[:config_file] = nil
    end
    
    it "should configure chef::config from a file" do
      Chef::Config.should_not_receive(:from_file).with("/etc/chef/default.rb")
      @app.configure_chef
    end
  end
  
  
  it "should merge the local config hash into chef::config" do
    Chef::Config.should_receive(:configure)
    @app.configure_chef
  end

end

describe Chef::Application, "configure_logging" do
  before do
    @app = Chef::Application.new
    Chef::Config.stub!(:[]).with(:log_location).and_return(STDOUT)
    Chef::Config.stub!(:[]).with(:log_level).and_return(:debug)
  end
  
  it "should initialise the chef logger" do
    Chef::Log.should_receive(:init).with(STDOUT).and_return(true)
    @app.configure_logging
  end

  it "should set the chef logger level" do
    Chef::Log.should_receive(:level).with(:debug).and_return(true)
    @app.configure_logging
  end
end

describe Chef::Application, "class method: fatal!" do
  before do
    Process.stub!(:exit).and_return(true)
  end
  
  it "should log an error message" do
    Chef::Log.should_receive(:fatal).with("blah").and_return(true)
    Chef::Application.fatal! "blah"
  end
  
  describe "when an exit code is supplied" do
    it "should exit with the given exit code" do
      Process.should_receive(:exit).with(-100).and_return(true)
      Chef::Application.fatal! "blah", -100
    end
  end
  
  describe "when an exit code is not supplied" do
    it "should exit with the default exit code" do
      Process.should_receive(:exit).with(-1).and_return(true)
      Chef::Application.fatal! "blah"
    end
  end
  
end

describe Chef::Application, "setup_application" do
  before do
    @app = Chef::Application.new
  end
  
  it "should raise an error" do
    lambda { @app.setup_application }.should raise_error(Chef::Exceptions::Application)
  end
end

describe Chef::Application, "run_application" do
  before do
    @app = Chef::Application.new
  end
  
  it "should raise an error" do
    lambda { @app.run_application }.should raise_error(Chef::Exceptions::Application)
  end
end