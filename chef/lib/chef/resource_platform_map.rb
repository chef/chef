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

      def initialize(map={:default => {}})
        @map = map
      end

      def filter(platform, version)
        resource_map = map[:default].clone
        platform_sym = platform
        if platform.kind_of?(String)
          platform.downcase!
          platform.gsub!(/\s/, "_")
          platform_sym = platform.to_sym
        end

        if map.has_key?(platform_sym)
          if map[platform_sym].has_key?(version)
            if map[platform_sym].has_key?(:default)
              resource_map.merge!(map[platform_sym][:default])
            end
            resource_map.merge!(map[platform_sym][version])
          elsif map[platform_sym].has_key?(:default)
            resource_map.merge!(map[platform_sym][:default])
          end
        end
        resource_map
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
        if args.has_key?(:platform)
          if args.has_key?(:version)
            if map.has_key?(args[:platform])
              if map[args[:platform]].has_key?(args[:version])
                map[args[:platform]][args[:version]][args[:short_name].to_sym] = args[:resource]
              else
                map[args[:platform]][args[:version]] = {
                  args[:short_name].to_sym => args[:resource]
                }
              end
            else
              map[args[:platform]] = {
                args[:version] => {
                  args[:short_name].to_sym => args[:resource]
                }
              }
            end
          else
            if map.has_key?(args[:platform])
              if map[args[:platform]].has_key?(:default)
                map[args[:platform]][:default][args[:short_name].to_sym] = args[:resource]
              else
                map[args[:platform]] = { :default => { args[:short_name].to_sym => args[:resource] } }
              end
            else
              map[args[:platform]] = {
                :default => {
                  args[:short_name].to_sym => args[:resource]
                }
              }
            end
          end
        else
          if map.has_key?(:default)
            map[:default][args[:short_name].to_sym] = args[:resource]
          else
            map[:default] = {
              args[:short_name].to_sym => args[:resource]
            }
          end
        end
      end

      def get(short_name, platform=nil, version=nil)
        resource_klass = platform_resource(short_name, platform, version) ||
                         resource_matching_short_name(short_name)

        raise NameError, "Cannot find a resource for #{short_name} on #{platform} version #{version}" if resource_klass.nil?

        resource_klass
      end

      private

      def platform_resource(short_name, platform, version)
        pmap = filter(platform, version)
        rtkey = short_name.kind_of?(Chef::Resource) ? short_name.resource_name.to_sym : short_name

        pmap.has_key?(rtkey) ? pmap[rtkey] : nil
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
