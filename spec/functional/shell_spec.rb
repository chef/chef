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
require 'chef/shell'
require 'chef/mixin/command/unix'

describe Shell do

  # chef-shell's unit tests are by necessity very mock-heavy, and frequently do
  # not catch cases where chef-shell fails to boot because of changes in
  # chef/client.rb
  describe "smoke tests", :unix_only => true do
    include Chef::Mixin::Command::Unix

    def read_until(io, expected_value)
      start = Time.new
      buffer = ""
      until buffer.include?(expected_value)
        begin
          buffer << io.read_nonblock(1)
        rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EIO, EOFError
          sleep 0.01
        end
        if Time.new - start > 30
          STDERR.puts "did not read expected value `#{expected_value}' within 15s"
          STDERR.puts "Buffer so far: `#{buffer}'"
          break
        end
      end
      buffer
    end

    def run_chef_shell_with(options)
      config = File.expand_path("shef-config.rb", CHEF_SPEC_DATA)
      path_to_chef_shell = File.expand_path("../../../bin/chef-shell", __FILE__)
      output = ''
      status = popen4("#{path_to_chef_shell} -c #{config} #{options}", :waitlast => true) do |pid, stdin, stdout, stderr|
        read_until(stdout, "chef >")
        yield stdout, stdin if block_given?
        stdin.write("'done'\n")
        output = read_until(stdout, '=> "done"')
        stdin.print("exit\n")
        read_until(stdout, "\n")
      end

      [output, status.exitstatus]
    end

    it "boots correctly with -lauto" do
      output, exitstatus = run_chef_shell_with("-lauto")
      output.should include("done")
      expect(exitstatus).to eq(0)
    end

    it "sets the log_level from the command line" do
      output, exitstatus = run_chef_shell_with("-lfatal") do |out, keyboard|
        show_log_level_code = %q[puts "===#{Chef::Log.level}==="]
        keyboard.puts(show_log_level_code)
        read_until(out, show_log_level_code)
      end
      output.should include("===fatal===")
      expect(exitstatus).to eq(0)
    end

  end

end
