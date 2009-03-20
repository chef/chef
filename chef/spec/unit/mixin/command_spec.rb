#
# Author:: Matthew Landauer (<matthew@openaustralia.org>)
# Copyright:: Copyright (c) 2008 Matthew Landauer
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Mixin::Command do
  before :each do
    Chef::Log.init
  end
  
  # Reset the logger for other tests
  after :each do
    Chef::Log.init
  end
  
  it "should log the command's standard output at debug log level" do
    command = "ruby -e 'puts 5'"
    Chef::Log.should_receive(:debug).with("Executing #{command}").ordered
    Chef::Log.should_receive(:debug).with("---- Begin output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("STDOUT: 5").ordered
    Chef::Log.should_receive(:debug).with("---- End output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("Ran #{command} returned 0").ordered
    Chef::Mixin::Command.run_command(:command => command)
  end
  
  it "should log the command's standard error at debug log level" do
    command = "ruby -e 'STDERR.puts 5'"
    Chef::Log.should_receive(:debug).with("Executing #{command}").ordered
    Chef::Log.should_receive(:debug).with("---- Begin output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("STDERR: 5").ordered
    Chef::Log.should_receive(:debug).with("---- End output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("Ran #{command} returned 0").ordered
    Chef::Mixin::Command.run_command(:command => command)
  end
  
  it "should log the command's standard out and error at the same time" do
    command = "ruby -e 'STDERR.puts 1; puts 2; STDERR.puts 3; puts 4'"
    Chef::Log.should_receive(:debug).with("Executing #{command}").ordered
    Chef::Log.should_receive(:debug).with("---- Begin output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("STDERR: 1").ordered
    Chef::Log.should_receive(:debug).with("STDOUT: 2").ordered
    Chef::Log.should_receive(:debug).with("STDERR: 3").ordered
    Chef::Log.should_receive(:debug).with("STDOUT: 4").ordered
    Chef::Log.should_receive(:debug).with("---- End output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("Ran #{command} returned 0").ordered
    Chef::Mixin::Command.run_command(:command => command)
  end

  it "should throw an exception if the command returns a bad exit value" do
    command = "ruby -e 'puts 1; exit 1'"
    Chef::Log.level :debug
    # Stub out Chef::Log.debug to avoid messages going to console
    Chef::Log.stub!(:debug)
    lambda {Chef::Mixin::Command.run_command(:command => command)}.should raise_error(Chef::Exceptions::Exec, "#{command} returned 1, expected 0")
  end

  it "should include the command output in the exception if the log level is not at debug" do
    command = "ruby -e 'puts 1; exit 1'"
    Chef::Log.level :info
    lambda {Chef::Mixin::Command.run_command(:command => command)}.should raise_error(Chef::Exceptions::Exec, "#{command} returned 1, expected 0\n---- Begin output of #{command} ----\nSTDOUT: 1\n---- End output of #{command} ----\n")
  end
  
  it "should log the output as the command is executing" do
    command = "ruby -e 'STDOUT.sync = true; puts 1; sleep 2; puts 2'"
    Chef::Log.should_receive(:debug).with("Executing #{command}").ordered
    Chef::Log.should_receive(:debug).with("---- Begin output of #{command} ----").ordered
    Chef::Log.should_receive(:debug).with("STDOUT: 1").ordered
    lambda {Chef::Mixin::Command.run_command(:command => command, :timeout => 1)}.should raise_error(Timeout::Error)
  end
end
