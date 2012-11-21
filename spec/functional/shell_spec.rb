#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'spec_helper'
require 'chef/version'

describe Chef::Shell do

  # chef-shell's unit tests are by necessity very mock-heavy, and frequently do
  # not catch cases where chef-shell fails to boot because of changes in
  # chef/client.rb
  describe "smoke tests", :unix_only => true do

    def run_chef_shell_with(options)
      # Windows ruby installs don't (always?) have PTY,
      # so hide the require here
      require 'pty'
      path_to_chef_shell = File.expand_path("../../../bin/chef-shell", __FILE__)
      reader, writer, pid = PTY.spawn("#{path_to_chef_shell} #{options}")
      yield writer if block_given?
      writer.puts("exit")
      output = reader.read
      exitstatus = Process.waitpid2(pid)[1]
      [output, exitstatus]
    end

    it "boots correctly with -lauto" do
      output, exitstatus = run_chef_shell_with("-lauto")
      exitstatus.should be_success
    end

    it "sets the log_level from the command line" do
      output, exitstatus = run_chef_shell_with("-lfatal") do |shell|
        shell.puts(%Q[puts "===\#\{Chef::Log.level}==="])
      end
      output.should include("===fatal===")
      exitstatus.should be_success
    end

  end

end
