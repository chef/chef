#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'timeout'
require 'win32/open3'

class Chef
  class ShellOut
    module Windows

      #--
      # Missing lots of features from the UNIX version, such as
      # environment, cwd, etc.
      def run_command
        Chef::Log.debug("sh(#{@command})")
        # win32 open4 is really just open3.
        Open3.popen3(@command) do |stdin,stdout,stderr|
          @finished_stdout = false
          @finished_stderr = false
          stdin.close
          stdout.sync = true
          stderr.sync = true

          Timeout.timeout(timeout) do
            loop do

              read_stdout(stdout)
              read_stderr(stderr)

              break if (@finished_stdout && @finished_stderr)
            end
            @status = $?
          end
        end

        self

      rescue Timeout::Error
        raise Chef::Exceptions::CommandTimeout, "command timed out:\n#{format_for_exception}"
      end

      def read_stdout(stdout)
        return nil if @finished_stdout
        if chunk = stdout.read_nonblock(8096)
          @stdout << chunk
        end
      rescue EOFError
        @finished_stdout = true
      rescue Errno::EAGAIN
      end

      def read_stderr(stderr)
        return nil if @finished_stderr
        if chunk = stderr.read_nonblock(8096)
          @stderr << chunk
        end
      rescue EOFError
        @finished_stderr = true
      rescue Errno::EAGAIN
      end

    end
  end
end
