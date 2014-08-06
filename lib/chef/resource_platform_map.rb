#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/mixin/params_validate'
require 'chef/mixin/convert_to_class_name'

class Chef
  class Resource
    class PlatformMap

      include Chef::Mixin::ParamsValidate
      include Chef::Mixin::ConvertToClassName

      attr_reader :map

      def initialize(map={})
        @map = map
      end

      def set(args)
        validate(
          args,
          {
            :platform => {
              :kind_of => Symbol,
              :required => false
            },
            :version => {
              :kind_of => String,
              :required => false
            },
            :short_name => {
              :kind_of => Symbol,
              :required => true
            },
            :resource => {
              :kind_of => [ String, Symbol, Class ],
              :required => true
            }
          }
        )
        platform = args[:platform] || :default
        version = args[:version] || :default
        map[platform] = {} if !map[platform]
        map[platform][version] = {} if !map[platform][version]
        map[platform][version][args[:short_name].to_sym] = args[:resource]
      end

      def get(short_name, platform=nil, version=nil)
        resource_klass = platform_resource(short_name, platform, version) ||
                         resource_matching_short_name(short_name)

        raise Exceptions::NoSuchResourceType, "Cannot find a resource for #{short_name} on #{platform} version #{version}" if resource_klass.nil?

        resource_klass
      end

      private

      def platform_resource(short_name, platform, version)
        platform_sym = platform
        if platform.kind_of?(String)
          platform.downcase!
          platform.gsub!(/\s/, "_")
          platform_sym = platform.to_sym
        end

        rtkey = short_name.kind_of?(Chef::Resource) ? short_name.resource_name.to_sym : short_name

        [ platform_sym, :default ].each do |platform_key|
          if map.has_key?(platform_key)
            [ version, :default ].each do |version_key|
              if map[platform_key].has_key?(version_key)
                if map[platform_key][version_key].has_key?(rtkey)
                  return map[platform_key][version_key][rtkey]
                end
              end
            end
          end
        end

        nil
      end

      def resource_matching_short_name(short_name)
        begin
          rname = convert_to_class_name(short_name.to_s)
          Chef::Resource.const_get(rname)
        rescue NameError
          nil
        end
      end

    end
  end
end
