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

describe Shell do

  # chef-shell's unit tests are by necessity very mock-heavy, and frequently do
  # not catch cases where chef-shell fails to boot because of changes in
  # chef/client.rb
  describe "smoke tests", :unix_only => true do

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

    def wait_or_die(pid)
      start = Time.new

      until exitstatus = Process.waitpid2(pid, Process::WNOHANG)
        if Time.new - start > 5
          STDERR.puts("chef-shell tty did not exit cleanly, killing it")
          Process.kill(:KILL, pid)
        end
        sleep 0.01
      end
      exitstatus[1]
    end

    def run_chef_shell_with(options)
      # Windows ruby installs don't (always?) have PTY,
      # so hide the require here
      require 'pty'
      config = File.expand_path("shef-config.rb", CHEF_SPEC_DATA)
      path_to_chef_shell = File.expand_path("../../../bin/chef-shell", __FILE__)
      reader, writer, pid = PTY.spawn("#{path_to_chef_shell} -c #{config} #{options}")
      read_until(reader, "chef >")
      yield reader, writer if block_given?
      writer.puts('"done"')
      output = read_until(reader, '=> "done"')
      writer.print("exit\n")
      read_until(reader, "exit")
      read_until(reader, "\n")
      read_until(reader, "\n")
      writer.close

      exitstatus = wait_or_die(pid)

      [output, exitstatus]
    rescue PTY::ChildExited => e
      [output, e.status]
    end

    it "boots correctly with -lauto" do
      output, exitstatus = run_chef_shell_with("-lauto")
      exitstatus.should be_success
    end

    it "sets the log_level from the command line" do
      output, exitstatus = run_chef_shell_with("-lfatal") do |out, keyboard|
        show_log_level_code = %q[puts "===#{Chef::Log.level}==="]
        keyboard.puts(show_log_level_code)
        read_until(out, show_log_level_code)
      end
      output.should include("===fatal===")
      exitstatus.should be_success
    end

  end

end
