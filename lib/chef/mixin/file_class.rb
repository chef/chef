#
# Author:: Mark Mzyk <mmzyk@chef.io>
# Author:: Seth Chisamore <schisamo@chef.io>
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

class Chef
  module Mixin
    module FileClass

      def file_class
        @host_os_file ||= if ChefConfig::Config.target_mode?
                            ::TargetIO::File
                          elsif ChefUtils.windows?
                            require_relative "../win32/file"
                            Chef::ReservedNames::Win32::File
                          else
                            ::File
                          end
      end
    end
  end
end
