#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

Dir[File.join(File.dirname(__FILE__), 'provider/**/*.rb')].sort.each { |lib| require lib }
require File.join(File.dirname(__FILE__), 'mixin', 'params_validate')

class Chef
  class Platform
        
    @platforms = {
      :mac_os_x => {},
      :ubuntu   => {},
      :centos   => {},
      :redhat   => {},
      :gentoo   => {},
      :solaris  => {},
      :default  => {
        :file => Chef::Provider::File,
        :directory => Chef::Provider::Directory,
        :link => Chef::Provider::Link,
      }
    }

    class << self
      attr_accessor :platforms
      
      include Chef::Mixin::ParamsValidate
            
      def find(name, version)
        provider_map = @platforms[:default].clone
        
        name_sym = name
        if name.kind_of?(String)
          name.downcase!
          name.gsub!(/\s/, "_")
          name_sym = name.to_sym
        end
        
        if @platforms.has_key?(name_sym)
          if @platforms[name_sym].has_key?(version) 
            Chef::Log.debug("Platform #{name.to_s} version #{version} found")
            if @platforms[name_sym].has_key?(:default)
              provider_map.merge!(@platforms[name_sym][:default])
            end
            provider_map.merge!(@platforms[name_sym][version])
          elsif @platforms[name_sym].has_key?(:default)
            provider_map.merge!(@platforms[name_sym][:default])
          end
        else
          Chef::Log.debug("Platform #{name} not found, using all defaults. (Unsupported platform?)")
        end
        provider_map
      end
      
      def find_provider(platform, version, resource_type)
        pmap = Chef::Platform.find(platform, version)
        rtkey = resource_type
        if resource_type.kind_of?(Chef::Resource)
          rtkey = resource_type.resource_name.to_sym
        end
        if pmap.has_key?(rtkey)
          pmap[rtkey]
        else
          Chef::Log.error("#{rtkey.inspect} #{pmap.inspect}")
          raise(
            ArgumentError, 
            "Cannot find a provider for #{resource_type} on #{platform} version #{version}"
          )
        end
      end
      
      def find_provider_for_node(node, resource_type)
        platform = nil
        version = nil
        if node.attribute?("lsbdistid")
          platform = node[:lsbdistid]
        elsif node.attribute?("macosx_productname")
          platform = node[:macosx_productname]
        elsif node.attribute?("operatingsystem")
          platform = node[:operatingsystem]
        end
        raise ArgumentError, "Cannot find a platform for #{node}" unless platform
        
        if node.attribute?("lsbdistrelease")
          version = node[:lsbdistrelease]
        elsif node.attribute?("macosx_productversion")
          version = node[:macosx_productversion]
        elsif node.attribute?("operatingsystemversion")
          version = node[:operatingsystemversion]
        end
        raise ArgumentError, "Cannot find a version for #{node}" unless version
        
        provider = find_provider(platform, version, resource_type)
      end
      
      def set(args)
        validate(
          args,
          {
            :platform => {
              :kind_of => Symbol,
              :required => false,
            },
            :version => {
              :kind_of => String,
              :required => false,
            },
            :resource => {
              :kind_of => Symbol,
            },
            :provider => {
              :kind_of => [ String, Symbol, Class ],
            }
          }
        )
        if args.has_key?(:platform)          
          if args.has_key?(:version)
            if @platforms.has_key?(args[:platform])
              if @platforms[args[:platform]].has_key?(args[:version])
                @platforms[args[:platform]][args[:version]][args[:resource].to_sym] = args[:provider]
              else
                @platforms[args[:platform]][args[:version]] = {
                  args[:resource].to_sym => args[:provider] 
                }
              end
            else
              @platforms[args[:platform]] = {
                args[:version] => {
                  args[:resource].to_sym => args[:provider]
                }
              }
            end
          else
            if @platforms.has_key?(args[:platform])            
              @platforms[args[:platform]][:default][args[:resource].to_sym] = args[:provider]
            else
              @platforms[args[:platform]] = {
                :default => {
                  args[:resource].to_sym => args[:provider]
                }
              }
            end
          end
        else
          if @platforms.has_key?(:default)
            @platforms[:default][args[:resource].to_sym] = args[:provider]
          else
            @platforms[:default] = {
              args[:resource].to_sym => args[:provider]
            }
          end
        end
      end
            
    end    
    
  end
end