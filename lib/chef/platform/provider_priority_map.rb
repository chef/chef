
require 'chef/providers'

class Chef
  class Platform
    class ProviderPriorityMap
      include Singleton

      def initialize
        load_default_map
      end

      def load_default_map

        #
        # Linux
        #

        # default block for linux O/Sen must come before platform_family exceptions
        priority :service, [
          Chef::Provider::Service::Systemd,
          Chef::Provider::Service::Insserv,
          Chef::Provider::Service::Redhat,
        ], os: "linux"

        priority :service, [
          Chef::Provider::Service::Systemd,
          Chef::Provider::Service::Arch,
        ], platform_family: "arch"

        priority :service, [
          Chef::Provider::Service::Systemd,
          Chef::Provider::Service::Gentoo,
        ], platform_family: "gentoo"

        priority :service, [
          # we can determine what systemd supports accurately
          Chef::Provider::Service::Systemd,
          # on debian-ish system if an upstart script exists that must win over sysv types
          Chef::Provider::Service::Upstart,
          Chef::Provider::Service::Insserv,
          Chef::Provider::Service::Debian,
          Chef::Provider::Service::Invokercd,
        ], platform_family: "debian"

        priority :service, [
          Chef::Provider::Service::Systemd,
          Chef::Provider::Service::Insserv,
          Chef::Provider::Service::Redhat,
        ], platform_family: [ "rhel", "fedora", "suse" ]

        #
        # BSDen
        #

        priority :service, Chef::Provider::Service::Freebsd, os: [ "freebsd", "netbsd" ]

        #
        # Solaris-en
        #

        priority :service, Chef::Provider::Service::Solaris, os: "solaris2"

        #
        # Mac
        #

        priority :service, Chef::Provider::Service::Macosx, os: "darwin"
      end

      def priority_map
        @priority_map ||= Chef::NodeMap.new
      end

      def priority(*args)
        priority_map.set(*args)
      end

    end
  end
end
