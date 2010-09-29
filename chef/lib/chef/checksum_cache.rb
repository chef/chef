#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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
require 'chef/mixin/convert_to_class_name'
require 'singleton'
require 'moneta'

class Chef 
  class Cache
    include Chef::Mixin::ConvertToClassName
    include ::Singleton
    
    attr_reader :moneta
    
    def initialize(*args)
      self.reset!(*args)
    end
    
    def reset!(backend=nil, options=nil)
      backend ||= Chef::Config[:cache_type]
      options ||= Chef::Config[:cache_options]
      
      begin
        require "moneta/#{convert_to_snake_case(backend, 'Moneta')}"
      rescue LoadError => e
        Chef::Log.fatal("Could not load Moneta back end #{backend.inspect}")
        raise e
      end
     
      @moneta = Moneta.const_get(backend).new(options)
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
