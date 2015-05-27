#
# Author:: Tyler Cloke (tyler@chef.io)
# Copyright:: Copyright 2015 Chef Software, Inc.
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
  module VersionedRest
    # Helper for getting a sane interface to passing an API version to Chef::REST
    # api_version should be a string of an integer
    def get_versioned_rest_object(url, api_version)
      Chef::REST.new(url, Chef::Config[:node_name], Chef::Config[:client_key], {:api_version => api_version})
    end
  end
end
