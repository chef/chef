#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require_relative "../knife"
require_relative "winrm_knife_base" # WinrmCommandSharedFunctions

class Chef
  class Knife
    class Winrm < Knife

      include Chef::Knife::WinrmCommandSharedFunctions

      deps do
        require_relative "windows_cert_generate"
        require_relative "windows_cert_install"
        require_relative "windows_listener_create"
        require_relative "winrm_session"
        require_relative "../search/query"
      end

      attr_writer :password

      banner "knife winrm QUERY COMMAND (options)"

      option :returns,
        long: "--returns CODES",
        description: "A comma delimited list of return codes which indicate success",
        default: "0"

      def run
        STDOUT.sync = STDERR.sync = true

        configure_session
        exit_status = run_command(@name_args[1..-1].join(" "))
        if exit_status != 0
          exit exit_status
        else
          exit_status
        end
      end
    end
  end
end
