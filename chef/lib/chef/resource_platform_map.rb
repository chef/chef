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

      extend Chef::Mixin::ParamsValidate
      extend Chef::Mixin::ConvertToClassName

      def self.platforms
        @platforms ||= {:default => {}}
      end

      def self.platforms=(platforms)
        @platforms = platforms
      end

      def self.find(platform, version)
        resource_map = platforms[:default].clone
        platform_sym = platform
        if platform.kind_of?(String)
          platform.downcase!
          platform.gsub!(/\s/, "_")
          platform_sym = platform.to_sym
        end

        if platforms.has_key?(platform_sym)
          if platforms[platform_sym].has_key?(version)
            Chef::Log.debug("Platform #{name.to_s} version #{version} found")
            if platforms[platform_sym].has_key?(:default)
              resource_map.merge!(platforms[platform_sym][:default])
            end
            resource_map.merge!(platforms[platform_sym][version])
          elsif platforms[platform_sym].has_key?(:default)
            resource_map.merge!(platforms[platform_sym][:default])
          end
        else
          Chef::Log.debug("Platform #{platform} not found, using all defaults. (Unsupported platform?)")
        end
        resource_map
      end

      # Returns a resource based on a nodes platform, version and
      # a short_name.
      #
      # ==== Parameters
      # node<Chef::Node>:: Node object to look up platform and version in
      # short_name<Symbol>:: short_name of the resource (ie :directory)
      #
      # === Returns
      # <Chef::Resource>:: returns the proper Chef::Resource class
      def self.find_resource_for_node(node, short_name)
        begin
          platform, version = Chef::Platform.find_platform_and_version(node)
        rescue ArgumentError
        end
        resource = find_resource(platform, version, short_name)
        resource
      end

      def self.set(args)
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
            if platforms.has_key?(args[:platform])
              if platforms[args[:platform]].has_key?(args[:version])
                platforms[args[:platform]][args[:version]][args[:short_name].to_sym] = args[:resource]
              else
                platforms[args[:platform]][args[:version]] = {
                  args[:short_name].to_sym => args[:resource]
                }
              end
            else
              platforms[args[:platform]] = {
                args[:version] => {
                  args[:short_name].to_sym => args[:resource]
                }
              }
            end
          else
            if platforms.has_key?(args[:platform])
              if platforms[args[:platform]].has_key?(:default)
                platforms[args[:platform]][:default][args[:short_name].to_sym] = args[:resource]
              else
                platforms[args[:platform]] = { :default => { args[:short_name].to_sym => args[:resource] } }
              end
            else
              platforms[args[:platform]] = {
                :default => {
                  args[:short_name].to_sym => args[:resource]
                }
              }
            end
          end
        else
          if platforms.has_key?(:default)
            platforms[:default][args[:short_name].to_sym] = args[:resource]
          else
            platforms[:default] = {
              args[:short_name].to_sym => args[:resource]
            }
          end
        end
      end

      def self.find_resource(platform, version, short_name)
        resource_klass = platform_resource(platform, version, short_name) ||
                         resource_matching_short_name(short_name)

        raise NameError, "Cannot find a resource for #{short_name} on #{platform} version #{version}" if resource_klass.nil?

        resource_klass
      end

      private

      def self.platform_resource(platform, version, short_name)
        pmap = find(platform, version)
        rtkey = short_name.kind_of?(Chef::Resource) ? short_name.resource_name.to_sym : short_name
        pmap.has_key?(rtkey) ? pmap[rtkey] : nil
      end

      def self.resource_matching_short_name(short_name)
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
