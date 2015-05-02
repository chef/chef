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
require 'chef/exceptions'
require 'chef/mixin/params_validate'
require 'chef/version_constraint/platform'

# This file depends on nearly every provider in chef, but requiring them
# directly causes circular requires resulting in uninitialized constant errors.
# Therefore, we do the includes inline rather than up top.
require 'chef/provider'


class Chef
  class Platform

    class << self
      attr_writer :platforms

      def platforms
        @platforms ||= begin
          require 'chef/providers'

          {
            :freebsd => {
              :default => {
                :group   => Chef::Provider::Group::Pw,
                :user    => Chef::Provider::User::Pw,
              }
            },
            :ubuntu   => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Debian,
              },
              ">= 11.10" => {
                :ifconfig => Chef::Provider::Ifconfig::Debian
              }
              # Chef::Provider::Service::Upstart is a candidate to be used in
              # ubuntu versions >= 13.10 but it currently requires all the
              # services to have an entry under /etc/init. We need to update it
              # to use the service ctl apis in order to migrate to using it on
              # ubuntu >= 13.10.
            },
            :gcel   => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Debian,
              }
            },
            :linaro   => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Debian,
              }
            },
            :raspbian   => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Debian,
              }
            },
            :linuxmint   => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Upstart,
              }
            },
            :debian => {
              :default => {
                :package => Chef::Provider::Package::Apt,
                :service => Chef::Provider::Service::Debian,
              },
              ">= 6.0" => {
                :service => Chef::Provider::Service::Insserv
              },
              ">= 7.0" => {
                :ifconfig => Chef::Provider::Ifconfig::Debian
              }
            },
            :xenserver   => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Yum,
              }
            },
            :xcp   => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Yum,
              }
            },
            :centos   => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Yum,
                :ifconfig => Chef::Provider::Ifconfig::Redhat
              },
              "< 7" => {
                :service => Chef::Provider::Service::Redhat
              }
            },
            :amazon   => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Yum,
              }
            },
            :scientific => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Yum,
              },
              "< 7" => {
                :service => Chef::Provider::Service::Redhat
              }
            },
            :fedora   => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Yum,
                :ifconfig => Chef::Provider::Ifconfig::Redhat
              },
              "< 15" => {
                :service => Chef::Provider::Service::Redhat
              }
            },
            :opensuse     => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Zypper,
                :group => Chef::Provider::Group::Suse
              },
              # Only OpenSuSE 12.3+ should use the Usermod group provider:
              ">= 12.3" => {
                :group => Chef::Provider::Group::Usermod
              }
            },
            :suse     => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Zypper,
                :group => Chef::Provider::Group::Gpasswd
              },
              "< 12.0" => {
                :group => Chef::Provider::Group::Suse,
                :service => Chef::Provider::Service::Redhat
              }
            },
            :oracle  => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Yum,
              },
              "< 7" => {
                :service => Chef::Provider::Service::Redhat
              }
            },
            :redhat   => {
              :default => {
                :service => Chef::Provider::Service::Systemd,
                :package => Chef::Provider::Package::Yum,
                :ifconfig => Chef::Provider::Ifconfig::Redhat
              },
              "< 7" => {
                :service => Chef::Provider::Service::Redhat
              }
            },
            :ibm_powerkvm   => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Yum,
                :ifconfig => Chef::Provider::Ifconfig::Redhat
              }
            },
            :cloudlinux   => {
              :default => {
                :service => Chef::Provider::Service::Redhat,
                :package => Chef::Provider::Package::Yum,
                :ifconfig => Chef::Provider::Ifconfig::Redhat
              }
            },
            :parallels   => {
                :default => {
                    :service => Chef::Provider::Service::Redhat,
                    :package => Chef::Provider::Package::Yum,
                    :ifconfig => Chef::Provider::Ifconfig::Redhat
                }
            },
            :gentoo   => {
              :default => {
                :package => Chef::Provider::Package::Portage,
                :service => Chef::Provider::Service::Gentoo,
              }
            },
            :arch   => {
              :default => {
                :package => Chef::Provider::Package::Pacman,
                :service => Chef::Provider::Service::Systemd,
              }
            },
            :solaris  => {},
            :openindiana => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Ips,
                :group => Chef::Provider::Group::Usermod
              }
            },
            :opensolaris => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Ips,
                :group => Chef::Provider::Group::Usermod
              }
            },
            :nexentacore => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Solaris,
                :group => Chef::Provider::Group::Usermod
              }
            },
            :omnios => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Ips,
                :group => Chef::Provider::Group::Usermod,
                :user => Chef::Provider::User::Solaris,
              }
            },
            :solaris2 => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Ips,
                :group => Chef::Provider::Group::Usermod,
                :user => Chef::Provider::User::Solaris,
              },
              "< 5.11" => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::Solaris,
                :group => Chef::Provider::Group::Usermod,
                :user => Chef::Provider::User::Solaris,
              }
            },
            :smartos => {
              :default => {
                :mount => Chef::Provider::Mount::Solaris,
                :package => Chef::Provider::Package::SmartOS,
                :group => Chef::Provider::Group::Usermod
              }
            },
            :hpux => {
              :default => {
                :group => Chef::Provider::Group::Usermod
              }
            },
            :aix => {
              :default => {
                :group => Chef::Provider::Group::Aix,
                :mount => Chef::Provider::Mount::Aix,
                :ifconfig => Chef::Provider::Ifconfig::Aix,
                :package => Chef::Provider::Package::Aix,
                :user => Chef::Provider::User::Aix,
                :service => Chef::Provider::Service::Aix
              }
            },
            :exherbo => {
              :default => {
                :package => Chef::Provider::Package::Paludis,
                :service => Chef::Provider::Service::Systemd,
              }
            },
            :default => {
              :mount => Chef::Provider::Mount::Mount,
              :user => Chef::Provider::User::Useradd,
              :group => Chef::Provider::Group::Gpasswd,
              :ifconfig => Chef::Provider::Ifconfig,
              :package => Chef::Provider::Package,
              :service => Chef::Provider::Service,
            }
          }
        end
      end

      include Chef::Mixin::ParamsValidate

      def find(name, version)
        provider_map = platforms[:default].clone

        name_sym = name
        if name.kind_of?(String)
          name.downcase!
          name.gsub!(/\s/, "_")
          name_sym = name.to_sym
        end

        if platforms.has_key?(name_sym)
          platform_versions = platforms[name_sym].select {|k, v| k != :default }
          if platforms[name_sym].has_key?(:default)
            provider_map.merge!(platforms[name_sym][:default])
          end
          platform_versions.each do |platform_version, provider|
            begin
              version_constraint = Chef::VersionConstraint::Platform.new(platform_version)
              if version_constraint.include?(version)
                Chef::Log.debug("Platform #{name.to_s} version #{version} found")
                provider_map.merge!(provider)
              end
            rescue Chef::Exceptions::InvalidPlatformVersion
              Chef::Log.debug("Chef::Version::Comparable does not know how to parse the platform version: #{version}")
            end
          end
        else
          Chef::Log.debug("Platform #{name} not found, using all defaults. (Unsupported platform?)")
        end
        provider_map
      end

      def find_platform_and_version(node)
        platform = nil
        version = nil

        if node[:platform]
          platform = node[:platform]
        elsif node.attribute?("os")
          platform = node[:os]
        end

        raise ArgumentError, "Cannot find a platform for #{node}" unless platform

        if node[:platform_version]
          version = node[:platform_version]
        elsif node[:os_version]
          version = node[:os_version]
        elsif node[:os_release]
          version = node[:os_release]
        end

        raise ArgumentError, "Cannot find a version for #{node}" unless version

        return platform, version
      end

      def provider_for_resource(resource, action=:nothing)
        node = resource.run_context && resource.run_context.node
        raise ArgumentError, "Cannot find the provider for a resource with no run context set" unless node
        provider = find_provider_for_node(node, resource).new(resource, resource.run_context)
        provider.action = action
        provider
      end

      def provider_for_node(node, resource_type)
        raise NotImplementedError, "#{self.class.name} no longer supports #provider_for_node"
      end

      def find_provider_for_node(node, resource_type)
        platform, version = find_platform_and_version(node)
        find_provider(platform, version, resource_type)
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
            if platforms.has_key?(args[:platform])
              if platforms[args[:platform]].has_key?(args[:version])
                platforms[args[:platform]][args[:version]][args[:resource].to_sym] = args[:provider]
              else
                platforms[args[:platform]][args[:version]] = {
                  args[:resource].to_sym => args[:provider]
                }
              end
            else
              platforms[args[:platform]] = {
                args[:version] => {
                  args[:resource].to_sym => args[:provider]
                }
              }
            end
          else
            if platforms.has_key?(args[:platform])
              if platforms[args[:platform]].has_key?(:default)
                platforms[args[:platform]][:default][args[:resource].to_sym] = args[:provider]
              elsif args[:platform] == :default
                platforms[:default][args[:resource].to_sym] = args[:provider]
              else
                platforms[args[:platform]] = { :default => { args[:resource].to_sym => args[:provider] } }
              end
            else
              platforms[args[:platform]] = {
                :default => {
                  args[:resource].to_sym => args[:provider]
                }
              }
            end
          end
        else
          if platforms.has_key?(:default)
            platforms[:default][args[:resource].to_sym] = args[:provider]
          else
            platforms[:default] = {
              args[:resource].to_sym => args[:provider]
            }
          end
        end
      end

      def find_provider(platform, version, resource_type)
        provider_klass = explicit_provider(platform, version, resource_type) ||
                         platform_provider(platform, version, resource_type) ||
                         resource_matching_provider(platform, version, resource_type)

        raise ArgumentError, "Cannot find a provider for #{resource_type} on #{platform} version #{version}" if provider_klass.nil?

        provider_klass
      end

      private

        def explicit_provider(platform, version, resource_type)
          resource_type.kind_of?(Chef::Resource) ? resource_type.provider : nil
        end

        def platform_provider(platform, version, resource_type)
          pmap = Chef::Platform.find(platform, version)
          rtkey = resource_type.kind_of?(Chef::Resource) ? resource_type.resource_name.to_sym : resource_type
          pmap.has_key?(rtkey) ? pmap[rtkey] : nil
        end

        def resource_matching_provider(platform, version, resource_type)
          if resource_type.kind_of?(Chef::Resource)
            begin
              class_name = resource_type.class.to_s.split('::').last
              result = Chef::Provider.const_get(class_name)
              Chef::Log.warn("Class Chef::Provider::#{class_name} does not declare 'provides #{resource_type.class.dsl_name.to_sym.inspect}'.")
              Chef::Log.warn("This will no longer work in Chef 13: you must use 'provides' to provide DSL.")
              result
            rescue NameError
              nil
            end
          else
            nil
          end
        end

    end
  end
end
