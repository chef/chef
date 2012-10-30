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

require 'spec_helper'

describe Chef::Mixin::Command do

  if windows?

    pending("TODO MOVE: this is a platform specific integration test.")

  else

    describe "popen4" do
      include Chef::Mixin::Command

      it "should be possible to read the child process's stdout and stderr" do
        popen4("sh -c 'echo hello && echo world >&2'") do |pid, stdin, stdout, stderr|
          stdout.read.should == "hello\n"
          stderr.read.should == "world\n"
        end
      end

      it "should default all commands to be run in the POSIX standard C locale" do
        popen4("echo $LC_ALL") do |pid, stdin, stdout, stderr|
          stdout.read.strip.should == "C"
        end
      end

      it "should respect locale when specified explicitly" do
        popen4("echo $LC_ALL", :environment => {"LC_ALL" => "es"}) do |pid, stdin, stdout, stderr|
          stdout.read.strip.should == "es"
        end
      end

      it "should end when the child process reads from STDIN and a block is given" do
        lambda {Timeout.timeout(10) do
            popen4("ruby -e 'while gets; end'", :waitlast => true) do |pid, stdin, stdout, stderr|
              (1..5).each { |i| stdin.puts "#{i}" }
            end
          end
        }.should_not raise_error
      end

      describe "when a process detaches but doesn't close STDOUT and STDERR [CHEF-584]" do

        it "returns immediately after the first child process exits" do
          lambda {Timeout.timeout(10) do
            pid, stdin,stdout,stderr = nil,nil,nil,nil
            evil_forker="exit if fork; 10.times { sleep 1}"
            popen4("ruby -e '#{evil_forker}'") do |pid,stdin,stdout,stderr|
            end
          end}.should_not raise_error
        end

      end

    end

    describe "run_command" do
      include Chef::Mixin::Command

      it "logs the command's stderr and stdout output if the command failed" do
        Chef::Log.stub!(:level).and_return(:debug)
        begin
          run_command(:command => "sh -c 'echo hello; echo world >&2; false'")
          violated "Exception expected, but nothing raised."
        rescue => e
          e.message.should =~ /STDOUT: hello/
          e.message.should =~ /STDERR: world/
        end
      end

      describe "when a process detaches but doesn't close STDOUT and STDERR [CHEF-584]" do
        it "returns successfully" do
          # CHEF-2916 might have added a slight delay here, or our CI
          # infrastructure is burdened. Bumping timeout from 2 => 4 --
          # btm
          # Serdar - During Solaris tests, we've seen that processes
          # are taking a long time to exit. Bumping timeout now to 10.
          lambda {Timeout.timeout(10) do
            evil_forker="exit if fork; 10.times { sleep 1}"
            run_command(:command => "ruby -e '#{evil_forker}'")
          end}.should_not raise_error
        end

      end
    end
  end
end
