#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/log'
require 'chef/config'
require 'moneta'

class Chef 
  class Cache

    attr_reader :moneta

    def initialize(type=nil, options=nil)
      type ||= Chef::Config[:cache_type]
      options ||= Chef::Config[:cache_options]

      if type == "BasicFile"
        require_type = "basic_file"
      else
        require_type = type.downcase
      end

      begin
        require "moneta/#{require_type}"
      rescue LoadError
        raise LoadError, "Cannot find a Moneta adaptor named #{require_type}!"
      end

      m = Moneta.const_get(type)
      @moneta = m.new(options)
    end

    def method_missing(method, *args)
      @moneta.send(method, *args)
    end

  end
end

module Moneta
  module Defaults
    def default
      nil
    end
  end
end
