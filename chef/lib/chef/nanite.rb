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

require 'chef'
require 'chef/config'
require 'chef/mixin/params_validate'
require 'json'

# The client doesn't use this class, so we are cool without having it
begin
  require 'nanite'
rescue LoadError
end

class Chef
  class Nanite 
   
    class << self

      def start_mapper(config={})
        Chef::Log.info("Running the Nanite Mapper")
        ::Nanite::Log.logger = Chef::Log.logger
        identity = Chef::Config[:nanite_identity] ? Chef::Config[:nanite_identity] : get_identity
        ::Nanite.start_mapper(
          :host => Chef::Config[:nanite_host], 
          :user => Chef::Config[:nanite_user],
          :pass => Chef::Config[:nanite_pass], 
          :vhost => Chef::Config[:nanite_vhost],
          :identity => identity,
          :format => :json,
          :log_level => Chef::Config[:log_level] 
        )
      end

      def get_identity(type="mapper")
        id = nil
        if Chef::FileCache.has_key?("nanite-#{type}-identity")
          id = Chef::FileCache.load("nanite-#{type}-identity")
        else
          id = ::Nanite::Identity.generate
          Chef::FileCache.store("nanite-#{type}-identity", id)
        end
        id
      end
      
      def request(*args)
        in_event do
          ::Nanite.request(*args)
        end
      end

      def in_event(&block)
        if EM.reactor_running?
          begin
            ::Nanite.ensure_mapper
          rescue ::Nanite::MapperNotRunning
            start_mapper
          end
          block.call
        else
          Chef::Log.warn("Starting Event Machine Loop")
          Thread.new do
            EM.run do
              start_mapper
              block.call
            end
          end
        end
      end

    end

  end
end
