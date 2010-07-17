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
    Dir.stub!(:chdir).and_return(0)
  end
  
  it "should create an instance of Chef::Application" do
    @app.should be_kind_of(Chef::Application)
  end
end

  
describe Chef::Application, "reconfigure" do
  before do
    @app = Chef::Application.new
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
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
      @app.stub!(:configure_chef).and_return(true)
      @app.stub!(:configure_logging).and_return(true)
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

describe Chef::Application, "configure_chef" do
  before do
    @app = Chef::Application.new
    Chef::Config.stub!(:merge!).and_return(true)
    @app.stub!(:parse_options).and_return(true)
  end
  
  it "should parse the commandline options" do
    @app.should_receive(:parse_options).and_return(true)
    @app.configure_chef
  end
  
  describe "when a config_file is present" do
    before do
      @app.config[:config_file] = "/etc/chef/default.rb"
      @cf = mock("cf")
      @cf.stub!(:path).and_return(@app.config[:config_file])
      @cf.stub!(:nil?).and_return(false)

      File.stub!(:open).and_return(@cf)
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
  
  describe "when the config_file is an URL" do
    before do
      @app.config[:config_file] = "http://example.com/foo.rb"
      @cf = mock("cf")
      @cf.stub!(:path).and_return("/tmp/some/path")
      @cf.stub!(:nil?).and_return(false)
      @rest = mock("rest")
      @rest.stub!(:get_rest).and_return(@rest)
      @rest.stub!(:open).and_yield(@cf)
      Chef::REST.stub!(:new).and_return(@rest)
    end
    
    it "should configure chef::config from an URL" do
      Chef::REST.should_receive(:new).with(@app.config[:config_file], nil, nil).at_least(1).times.and_return(@rest)
      @app.configure_chef
    end
  end
  
  
  it "should merge the local config hash into chef::config" do
    Chef::Config.should_receive(:merge!).and_return(true)
    @app.configure_chef
  end

end

describe Chef::Application, "configure_logging" do
  before do
    @app = Chef::Application.new
    Chef::Log.stub!(:init)
    Chef::Log.stub!(:level=)
  end
  
  it "should initialise the chef logger" do
    Chef::Log.should_receive(:init).with(Chef::Config[:log_location]).and_return(true)
    @app.configure_logging
  end

  it "should initialise the chef logger level" do
    Chef::Log.should_receive(:level=).with(Chef::Config[:log_level]).and_return(true)
    @app.configure_logging
  end

end

describe Chef::Application, "class method: fatal!" do
  before do
    STDERR.stub!(:puts).with("FATAL: blah").and_return(true)
    Chef::Log.stub!(:fatal).with("blah").and_return(true)
    Process.stub!(:exit).and_return(true)
  end
  
  it "should log an error message to the logger" do
    Chef::Log.should_receive(:fatal).with("blah").and_return(true)
    Chef::Application.fatal! "blah"
  end

  it "should log an error message on STDERR" do
    STDERR.should_receive(:puts).with("FATAL: blah").and_return(true)
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
