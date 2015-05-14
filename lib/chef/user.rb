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
require 'chef/user_v0'
require 'chef/user_v1'

class Chef
  # Proxy object for Chef::UserV0 and Chef::UserV1
  class User < BasicObject

    SUPPORTED_VERSIONS = [0,1]

    attr_reader :proxy_object

    def initialize(version=0)
      unless SUPPORTED_VERSIONS.include?(version)
        # something about inherting from BasicObject is forcing me to use :: in front of Chef::<whatever>
        raise ::Chef::Exceptions::InvalidObjectAPIVersionRequested, "You requested Chef::User version #{version}. Valid versions include #{SUPPORTED_VERSIONS.join(', ')}."
      end

      if version == 0
        @proxy_class = ::Chef::UserV0
        @proxy_object = @proxy_class.new
      elsif version == 1
        @proxy_class = ::Chef::UserV1
        @proxy_object = @proxy_class.new
      end
    end

    def method_missing(method, *args, &block)
      @proxy_object.send(method, *args, &block)
    end

    def self.method_missing(method, *arguments, &block)
      puts "halp"*100
      puts method
      puts @proxy_class.class
      @proxy_class.send(method, *args, &block)
    end

  end
end
