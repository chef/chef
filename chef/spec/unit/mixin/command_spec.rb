#
# Author:: Hongli Lai (hongli@phusion.nl)
# Copyright:: Copyright (c) 2009 Phusion
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

describe Chef::Mixin::Command, "popen4" do
  
  include Chef::Mixin::Command
  
  it "should be possible to read the child process's stdout and stderr" do
    popen4("sh -c 'echo hello && echo world >&2'") do |pid, stdin, stdout, stderr|
      stdout.read.should == "hello\n"
      stderr.read.should == "world\n"
    end
  end

end

describe Chef::Mixin::Command, "run_command" do
  
  include Chef::Mixin::Command
  
  it "logs the command's stderr and stdout output if the command failed" do
    begin
      run_command(:command => "sh -c 'echo hello; echo world >&2; false'")
      violated "Exception expected, but nothing raised."
    rescue => e
      e.message.should =~ /STDOUT: hello/
      e.message.should =~ /STDERR: world/
    end
  end
  
end