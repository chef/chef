#
# Author:: Mike Dodge (<mikedodge04@gmail.com>)
# Copyright:: Copyright 2015-2016, Facebook, Inc.
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

require_relative "service"

class Chef
  class Resource
    class MacosxService < Chef::Resource::Service
      resource_name :macosx_service
      provides :macosx_service
      provides :service, os: "darwin"

      description "Use the macosx_service resource to manage services on the macOS platform."

      property :plist, String,
               description: "A plist to use in the case where the filename and label for the service do not match."

      property :session_type, String

    end
  end
end
