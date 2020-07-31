#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2011-2016 Chef Software, Inc.
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
require "chef/server_api"
class Chef
  module Mixin
    module RootRestv0
      def root_rest
        # Use v0 API for now
        # Rather than upgrade all of this code to move to v1, the goal is to remove the
        # need for this plugin.  See
        # https://github.com/chef/chef/issues/3517
        @root_rest ||= Chef::ServerAPI.new(Chef::Config[:chef_server_root])
      end
    end
  end
end
