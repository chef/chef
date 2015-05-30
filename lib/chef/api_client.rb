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

require 'chef/exceptions'
require 'chef/api_client_v0'
require 'chef/api_client_v1'

class Chef
  # Proxy object for Chef::ApiClientV0 and Chef::ApiClientV1
  class ApiClient < BasicObject

    SUPPORTED_VERSIONS = [0,1]

    attr_reader :proxy_object

    def initialize(version=0)
      unless SUPPORTED_VERSIONS.include?(version)
        # something about inherting from BasicObject is forcing me to use :: in front of Chef::<whatever>
        raise ::Chef::Exceptions::InvalidObjectAPIVersionRequested, "You requested Chef::ApiClient version #{version}. Valid versions include #{SUPPORTED_VERSIONS.join(', ')}."
      end

      if version == 0
        @proxy_object = ::Chef::ApiClientV0.new
      elsif version == 1
        @proxy_object = ::Chef::ApiClientV1.new
      end
    end

    def method_missing(method, *args, &block)
      @proxy_object.send(method, *args, &block)
    end

    def self.method_missing(method, *arguments, &block)
      @proxy_class.send(method, *args, &block)
    end

  end
end
