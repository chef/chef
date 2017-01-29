#
# Author:: Mal Graty (<mal.graty@googlemail.com>)
# Copyright:: Copyright 2013-2017, Chef Software Inc.
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

require "chef/mixin/which"

class Chef
  class Resource
    class File
      class Verification

        #
        # Systemd provides a binary for verifying the correctness of
        # unit files.  Unfortunately some units have constraints on the
        # filename meaning that normal verification against temp files
        # won't work.
        #
        # Working around that requires placing a copy of the temp file
        # in a temp directory, under its real name and running the
        # verification tool against that file.
        #

        class SystemdUnit < Chef::Resource::File::Verification
          include Chef::Mixin::Which

          provides :systemd_unit

          def initialize(parent_resource, command, opts, &block)
            super
            @command = systemd_analyze_cmd
          end

          def verify(path, opts = {})
            return true unless systemd_analyze_path
            Dir.mktmpdir("chef-systemd-unit") do |dir|
              temp = "#{dir}/#{::File.basename(@parent_resource.path)}"
              ::FileUtils.cp(path, temp)
              verify_command(temp, opts)
            end
          end

          def systemd_analyze_cmd
            @systemd_analyze_cmd ||= "#{systemd_analyze_path} verify %{path}"
          end

          def systemd_analyze_path
            @systemd_analyze_path ||= which("systemd-analyze")
          end
        end
      end
    end
  end
end
