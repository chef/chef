#--
# Author:: Lamont Granquist <lamont@chef.io>
# Copyright:: Copyright 2010-2018, Chef Software Inc.
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

class Chef
  module Mixin
    module Which
      require_relative "../chef_class"

      def which(*cmds, extra_path: nil, &block)
        where(*cmds, extra_path: extra_path, &block).first || false
      end

      def where(*cmds, extra_path: nil, &block)
        # NOTE: unnecessarily duplicates function of path_sanity
        extra_path ||= [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
        paths = env_path.split(File::PATH_SEPARATOR) + Array(extra_path)
        cmds.map do |cmd|
          paths.map do |path|
            filename = Chef.path_to(File.join(path, cmd))
            filename if valid_executable?(filename, &block)
          end.compact
        end.flatten
      end

      private

      # for test stubbing
      def env_path
        if Chef::Config.target_mode?
          Chef.run_context.transport_connection.run_command("echo $PATH").stdout
        else
          ENV["PATH"]
        end
      end

      def valid_executable?(filename, &block)
        is_executable =
          if Chef::Config.target_mode?
            connection = Chef.run_context.transport_connection
            connection.file(filename).stat[:mode] & 1 && !connection.file(filename).directory?
          else
            File.executable?(filename) && !File.directory?(filename)
          end
        return false unless is_executable
        block ? yield(filename) : true
      end
    end
  end
end
