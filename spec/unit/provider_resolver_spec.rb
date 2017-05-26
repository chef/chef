#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

require "spec_helper"
require "chef/mixin/convert_to_class_name"
require "chef/provider_resolver"
require "chef/platform/service_helpers"
require "support/shared/integration/integration_helper"
require "tmpdir"
require "fileutils"

include Chef::Mixin::ConvertToClassName

# Open up Provider so we can write things down easier in here
#module Chef::Provider

describe Chef::ProviderResolver do
  include IntegrationSupport

  # Root the filesystem under a temp directory so Chef.path_to will point at it
  when_the_repository "is empty" do
    before do
      allow(Chef).to receive(:path_to) { |path| File.join(path_to(""), path) }
    end

    let(:resource_name) { :service }
    let(:provider) { nil }
    let(:action) { :start }

    let(:node) do
      node = Chef::Node.new
      node.automatic[:os] = os
      node.automatic[:platform_family] = platform_family
      node.automatic[:platform] = platform
      node.automatic[:platform_version] = platform_version
      node.automatic[:kernel] = { machine: "i386" }
      node
    end
    let(:run_context) { Chef::RunContext.new(node, nil, nil) }

    let(:provider_resolver) { Chef::ProviderResolver.new(node, resource, action) }
    let(:resolved_provider) do
      begin
        resource ? resource.provider_for_action(action).class : nil
      rescue Chef::Exceptions::ProviderNotFound
        nil
      end
    end

    let(:service_name) { "test" }
    let(:resource) do
      resource_class = Chef::ResourceResolver.resolve(resource_name, node: node)
      if resource_class
        resource = resource_class.new(service_name, run_context)
        resource.provider = provider if provider
      end
      resource
    end

    def self.on_platform(platform, *tags,
      platform_version: "11.0.1",
      platform_family: nil,
      os: nil,
      &block)
      Array(platform).each do |platform|
        Array(platform_version).each do |platform_version|
          on_one_platform(platform, platform_version, platform_family || platform, os || platform_family || platform, *tags, &block)
        end
      end
    end

    def self.on_one_platform(platform, platform_version, platform_family, os, *tags, &block)
      describe "on #{platform} #{platform_version}, platform_family: #{platform_family}, os: #{os}", *tags do
        let(:os)               { os }
        let(:platform)         { platform }
        let(:platform_family)  { platform_family }
        let(:platform_version) { platform_version }

        define_singleton_method(:os) { os }
        define_singleton_method(:platform) { platform }
        define_singleton_method(:platform_family) { platform_family }
        define_singleton_method(:platform_version) { platform_version }

        instance_eval(&block)
      end
    end

    def self.expect_providers(**providers)
      providers.each do |name, expected|
        describe name.to_s do
          let(:resource_name) { name }

          tags = []
          expected_provider = nil
          expected_resource = nil
          Array(expected).each do |p|
            if p.is_a?(Class) && p <= Chef::Provider
              expected_provider = p
            elsif p.is_a?(Class) && p <= Chef::Resource
              expected_resource = p
            else
              tags << p
            end
          end

          if expected_resource && expected_provider
            it "'#{name}' resolves to resource #{expected_resource} and provider #{expected_provider}", *tags do
              expect(resource.class).to eql(expected_resource)
              provider = double(expected_provider, class: expected_provider)
              expect(provider).to receive(:action=).with(action)
              expect(expected_provider).to receive(:new).with(resource, run_context).and_return(provider)
              expect(resolved_provider).to eql(expected_provider)
            end
          elsif expected_provider
            it "'#{name}' resolves to provider #{expected_provider}", *tags do
              provider = double(expected_provider)
              expect(provider).to receive(:action=).with(action)
              expect(expected_provider).to receive(:new).with(resource, run_context).and_return(provider)
              expect(resolved_provider).to eql(expected_provider)
            end
          else
            it "'#{name}' fails to resolve (since #{name.inspect} is unsupported on #{platform} #{platform_version})", *tags do
              Chef::Config[:treat_deprecation_warnings_as_errors] = false
              expect(resolved_provider).to be_nil
            end
          end
        end
      end
    end

    describe "resolving service resource" do
      def stub_service_providers(*services)
        services.each do |service|
          case service
          when :debian
            file "usr/sbin/update-rc.d", ""
          when :invokercd
            file "usr/sbin/invoke-rc.d", ""
          when :insserv
            file "sbin/insserv", ""
          when :upstart
            file "sbin/initctl", ""
          when :redhat
            file "sbin/chkconfig", ""
          when :systemd
            file "proc/1/comm", "systemd\n"
          else
            raise ArgumentError, service
          end
        end
      end

      def stub_service_configs(*configs)
        configs.each do |config|
          case config
          when :initd
            file "etc/init.d/#{service_name}", ""
          when :upstart
            file "etc/init/#{service_name}.conf", ""
          when :xinetd
            file "etc/xinetd.d/#{service_name}", ""
          when :etc_rcd
            file "etc/rc.d/#{service_name}", ""
          when :usr_local_etc_rcd
            file "usr/local/etc/rc.d/#{service_name}", ""
          when :systemd
            file "proc/1/comm", "systemd\n"
            file "etc/systemd/system/#{service_name}.service", ""
          else
            raise ArgumentError, config
          end
        end
      end

      shared_examples_for "an ubuntu platform with upstart, update-rc.d and systemd" do
        before do
          stub_service_providers(:debian, :invokercd, :upstart, :systemd)
        end

        it "when both the SysV init and Systemd script exists, it returns a Service::Debian provider" do
          stub_service_configs(:initd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when SysV, Upstart, and Systemd scripts exist, it returns a Service::Systemd provider" do
          stub_service_configs(:initd, :upstart, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when both the Upstart and Systemd scripts exists, it returns a Service::Systemd provider" do
          stub_service_configs(:upstart, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when both do not exist, it calls the old style provider resolver and returns a Systemd Provider" do
          stub_service_configs(:systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when only the SysV init script exists, it returns a Service::Systemd provider" do
          stub_service_configs(:initd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when both SysV and Upstart scripts exist, it returns a Service::Systemd provider" do
          stub_service_configs(:initd, :upstart)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end

        it "when only the Upstart script exists, it returns a Service::Upstart provider" do
          stub_service_configs(:upstart)
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end

        it "when both do not exist, it calls the old style provider resolver and returns a Systemd Provider" do
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end
      end

      shared_examples_for "an ubuntu platform with upstart and update-rc.d" do
        before do
          stub_service_providers(:debian, :invokercd, :upstart)
        end

        # needs to be handled by the highest priority init.d handler
        context "when only the SysV init script exists" do
          before do
            stub_service_configs(:initd)
          end

          it "enables init, invokercd, debian and upstart providers" do
            expect(provider_resolver.enabled_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd,
              Chef::Provider::Service::Upstart
            )
          end

          it "supports all the enabled handlers except for upstart" do
            expect(provider_resolver.supported_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd
            )
            expect(provider_resolver.supported_handlers).to_not include(
              Chef::Provider::Service::Upstart
            )
          end

          it "returns a Service::Debian provider" do
            expect(resolved_provider).to eql(Chef::Provider::Service::Debian)
          end
        end

        # on ubuntu this must be handled by upstart, the init script will exit 1 and fail
        context "when both SysV and Upstart scripts exist" do
          before do
            stub_service_configs(:initd, :upstart)
          end

          it "enables init, invokercd, debian and upstart providers" do
            expect(provider_resolver.enabled_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd,
              Chef::Provider::Service::Upstart
            )
          end

          it "supports all the enabled handlers" do
            expect(provider_resolver.supported_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd,
              Chef::Provider::Service::Upstart
            )
          end

          it "returns a Service::Upstart provider" do
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end
        end

        # this case is a pure-upstart script which is easy
        context "when only the Upstart script exists" do
          before do
            stub_service_configs(:upstart)
          end

          it "enables init, invokercd, debian and upstart providers" do
            expect(provider_resolver.enabled_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd,
              Chef::Provider::Service::Upstart
            )
          end

          it "supports only the upstart handler" do
            expect(provider_resolver.supported_handlers).to include(
              Chef::Provider::Service::Upstart
            )
            expect(provider_resolver.supported_handlers).to_not include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd
            )
          end

          it "returns a Service::Upstart provider" do
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end
        end

        # this case is important to get correct for why-run when no config is setup
        context "when both do not exist" do
          before do
            stub_service_configs
          end

          it "enables init, invokercd, debian and upstart providers" do
            expect(provider_resolver.enabled_handlers).to include(
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd,
              Chef::Provider::Service::Upstart
            )
          end

          it "no providers claim to support the resource" do
            expect(provider_resolver.supported_handlers).to_not include(
              Chef::Provider::Service::Upstart,
              Chef::Provider::Service::Debian,
              Chef::Provider::Service::Init,
              Chef::Provider::Service::Invokercd
            )
          end

          it "returns a Debian Provider" do
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end
        end
      end

      shared_examples_for "a debian platform using the insserv provider" do
        context "with a default install" do
          before do
            stub_service_providers(:debian, :invokercd, :insserv)
          end

          it "uses the Service::Insserv Provider to manage sysv init scripts" do
            stub_service_configs(:initd)
            expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
          end

          it "uses the Service::Insserv Provider when there is no config" do
            stub_service_configs
            expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
          end
        end

        context "when the user has installed upstart" do
          before do
            stub_service_providers(:debian, :invokercd, :insserv, :upstart)
          end

          it "when only the SysV init script exists, it returns an Insserv  provider" do
            stub_service_configs(:initd)
            expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
          end

          it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
            stub_service_configs(:initd, :upstart)
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end

          it "when only the Upstart script exists, it returns a Service::Upstart provider" do
            stub_service_configs(:upstart)
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end

          it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
            stub_service_configs
            expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
          end
        end
      end

      on_platform "ubuntu", platform_version: "15.10", platform_family: "debian", os: "linux" do
        it_behaves_like "an ubuntu platform with upstart, update-rc.d and systemd"

        it "when the unit-files are missing and system-ctl list-unit-files returns an error" do
          stub_service_providers(:debian, :invokercd, :upstart, :systemd)
          stub_service_configs(:initd, :upstart)
          mock_shellout_command("/bin/systemctl list-unit-files", exitstatus: 1)
          expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
        end
      end

      on_platform "ubuntu", platform_version: "14.10", platform_family: "debian", os: "linux" do
        it_behaves_like "an ubuntu platform with upstart, update-rc.d and systemd"
      end

      on_platform "ubuntu", platform_version: "14.04", platform_family: "debian", os: "linux" do
        it_behaves_like "an ubuntu platform with upstart and update-rc.d"
      end

      on_platform "ubuntu", platform_version: "10.04", platform_family: "debian", os: "linux" do
        it_behaves_like "an ubuntu platform with upstart and update-rc.d"
      end

      # old debian uses the Debian provider (does not have insserv or upstart, or update-rc.d???)
      on_platform "debian", platform_version: "4.0", os: "linux" do
        #it_behaves_like "a debian platform using the debian provider"
      end

      # Debian replaced the debian provider with insserv in the FIXME:VERSION distro
      on_platform "debian", platform_version: "7.0", os: "linux" do
        it_behaves_like "a debian platform using the insserv provider"
      end

      on_platform %w{solaris2 openindiana opensolaris nexentacore omnios smartos}, os: "solaris2", platform_version: "5.11" do
        it "returns a Solaris provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Solaris)
        end

        it "always returns a Solaris provider" do
          # no matter what we stub on the next two lines we should get a Solaris provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :usr_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Solaris)
        end
      end

      on_platform %w{mswin mingw32 windows}, platform_family: "windows", platform_version: "5.11" do
        it "returns a Windows provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Windows)
        end

        it "always returns a Windows provider" do
          # no matter what we stub on the next two lines we should get a Windows provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :usr_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Windows)
        end
      end

      on_platform %w{mac_os_x mac_os_x_server}, os: "darwin", platform_family: "mac_os_x", platform_version: "10.9.2" do
        it "returns a Macosx provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Macosx)
        end

        it "always returns a Macosx provider" do
          # no matter what we stub on the next two lines we should get a Macosx provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :usr_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Macosx)
        end
      end

      on_platform "freebsd", os: "freebsd", platform_version: "10.3" do
        it "returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:usr_local_etc_rcd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "returns a Freebsd provider if it finds the /etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:etc_rcd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :usr_local_etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:usr_local_etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a freebsd provider by default?" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end
      end

      on_platform "netbsd", os: "netbsd", platform_version: "7.0.1" do
        it "returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:usr_local_etc_rcd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "returns a Freebsd provider if it finds the /etc/rc.d initscript" do
          stub_service_providers
          stub_service_configs(:etc_rcd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :usr_local_etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:usr_local_etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a Freebsd provider if it finds the /usr/local/etc/rc.d initscript" do
          # should only care about :etc_rcd stub in the service configs
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:etc_rcd, :initd, :upstart, :xinetd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end

        it "always returns a freebsd provider by default?" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end
      end

    end

    PROVIDERS =
      {
        bash:                   [ Chef::Resource::Bash, Chef::Provider::Script ],
        breakpoint:             [ Chef::Resource::Breakpoint, Chef::Resource::Breakpoint.action_class ],
        chef_gem:               [ Chef::Resource::ChefGem, Chef::Provider::Package::Rubygems ],
        cookbook_file:          [ Chef::Resource::CookbookFile, Chef::Provider::CookbookFile ],
        csh:                    [ Chef::Resource::Csh, Chef::Provider::Script ],
        deploy:                 [ Chef::Resource::Deploy, Chef::Provider::Deploy::Timestamped ],
        deploy_revision:        [ Chef::Resource::DeployRevision, Chef::Provider::Deploy::Revision ],
        directory:              [ Chef::Resource::Directory, Chef::Provider::Directory ],
        erl_call:               [ Chef::Resource::ErlCall, Chef::Provider::ErlCall ],
        execute:                [ Chef::Resource::Execute, Chef::Provider::Execute ],
        file:                   [ Chef::Resource::File, Chef::Provider::File ],
        gem_package:            [ Chef::Resource::GemPackage, Chef::Provider::Package::Rubygems ],
        git:                    [ Chef::Resource::Git, Chef::Provider::Git ],
        group:                  [ Chef::Resource::Group, Chef::Provider::Group::Gpasswd ],
        homebrew_package:       [ Chef::Resource::HomebrewPackage, Chef::Provider::Package::Homebrew ],
        http_request:           [ Chef::Resource::HttpRequest, Chef::Provider::HttpRequest ],
        ifconfig:               [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
        link:                   [ Chef::Resource::Link, Chef::Provider::Link ],
        log:                    [ Chef::Resource::Log, Chef::Provider::Log::ChefLog ],
        macports_package:       [ Chef::Resource::MacportsPackage, Chef::Provider::Package::Macports ],
        mdadm:                  [ Chef::Resource::Mdadm, Chef::Provider::Mdadm ],
        mount:                  [ Chef::Resource::Mount, Chef::Provider::Mount::Mount ],
        perl:                   [ Chef::Resource::Perl, Chef::Provider::Script ],
        portage_package:        [ Chef::Resource::PortagePackage, Chef::Provider::Package::Portage ],
        python:                 [ Chef::Resource::Python, Chef::Provider::Script ],
        remote_directory:       [ Chef::Resource::RemoteDirectory, Chef::Provider::RemoteDirectory ],
        route:                  [ Chef::Resource::Route, Chef::Provider::Route ],
        ruby:                   [ Chef::Resource::Ruby, Chef::Provider::Script ],
        ruby_block:             [ Chef::Resource::RubyBlock, Chef::Provider::RubyBlock ],
        script:                 [ Chef::Resource::Script, Chef::Provider::Script ],
        subversion:             [ Chef::Resource::Subversion, Chef::Provider::Subversion ],
        template:               [ Chef::Resource::Template, Chef::Provider::Template ],
        timestamped_deploy:     [ Chef::Resource::TimestampedDeploy, Chef::Provider::Deploy::Timestamped ],
        aix_user:               [ Chef::Resource::User::AixUser, Chef::Provider::User::Aix ],
        dscl_user:              [ Chef::Resource::User::DsclUser, Chef::Provider::User::Dscl ],
        linux_user:             [ Chef::Resource::User::LinuxUser, Chef::Provider::User::Linux ],
        pw_user:                [ Chef::Resource::User::PwUser, Chef::Provider::User::Pw ],
        solaris_user:           [ Chef::Resource::User::SolarisUser, Chef::Provider::User::Solaris ],
        windows_user:           [ Chef::Resource::User::WindowsUser, Chef::Provider::User::Windows ],
        whyrun_safe_ruby_block: [ Chef::Resource::WhyrunSafeRubyBlock, Chef::Provider::WhyrunSafeRubyBlock ],

        # We want to check that these are unsupported:
        apt_package: nil,
        bff_package: nil,
        dpkg_package: nil,
        dsc_script: nil,
        ips_package: nil,
        pacman_package: nil,
        paludis_package: nil,
        rpm_package: nil,
        smartos_package: nil,
        solaris_package: nil,
        yum_package: nil,
        windows_package: nil,
        windows_service: nil,

        "linux" => {
          apt_package:     [ Chef::Resource::AptPackage, Chef::Provider::Package::Apt ],
          dpkg_package:    [ Chef::Resource::DpkgPackage, Chef::Provider::Package::Dpkg ],
          pacman_package:  [ Chef::Resource::PacmanPackage, Chef::Provider::Package::Pacman ],
          paludis_package: [ Chef::Resource::PaludisPackage, Chef::Provider::Package::Paludis ],
          rpm_package:     [ Chef::Resource::RpmPackage, Chef::Provider::Package::Rpm ],
          yum_package:     [ Chef::Resource::YumPackage, Chef::Provider::Package::Yum ],

          "debian" => {
            ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig::Debian ],
            package:  [ Chef::Resource::AptPackage, Chef::Provider::Package::Apt ],
    #        service: [ Chef::Resource::DebianService, Chef::Provider::Service::Debian ],

            "debian" => {
              "7.0" => {
              },
              "6.0" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
    #            service: [ Chef::Resource::InsservService, Chef::Provider::Service::Insserv ],
              },
              "5.0" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
              },
            },
            "gcel" => {
              "3.1.4" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
              },
            },
            "linaro" => {
              "3.1.4" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
              },
            },
            "linuxmint" => {
              "3.1.4" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
    #            service: [ Chef::Resource::UpstartService, Chef::Provider::Service::Upstart ],
              },
            },
            "raspbian" => {
              "3.1.4" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
              },
            },
            "ubuntu" => {
              "11.10" => {
              },
              "10.04" => {
                ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig ],
              },
            },
          },

          "arch" => {
            # TODO should be Chef::Resource::PacmanPackage
            package: [ Chef::Resource::Package, Chef::Provider::Package::Pacman ],

            "arch" => {
              "3.1.4" => {
              },
            },
          },

          "suse" => {
            group: [ Chef::Resource::Group, Chef::Provider::Group::Gpasswd ],
            "suse" => {
              "12.0" => {
              },
              %w{11.1 11.2 11.3} => {
                group: [ Chef::Resource::Group, Chef::Provider::Group::Suse ],
              },
            },
            "opensuse" => {
    #          service: [ Chef::Resource::RedhatService, Chef::Provider::Service::Redhat ],
              package: [ Chef::Resource::ZypperPackage, Chef::Provider::Package::Zypper ],
              group:   [ Chef::Resource::Group, Chef::Provider::Group::Usermod ],
              "12.3" => {
              },
              "12.2" => {
                group: [ Chef::Resource::Group, Chef::Provider::Group::Suse ],
              },
            },
          },

          "gentoo" => {
            # TODO should be Chef::Resource::PortagePackage
            package:         [ Chef::Resource::Package, Chef::Provider::Package::Portage ],
            portage_package: [ Chef::Resource::PortagePackage, Chef::Provider::Package::Portage ],
    #        service: [ Chef::Resource::GentooService, Chef::Provider::Service::Gentoo ],

            "gentoo" => {
              "3.1.4" => {
              },
            },
          },

          "rhel" => {
    #        service: [ Chef::Resource::SystemdService, Chef::Provider::Service::Systemd ],
            package:  [ Chef::Resource::YumPackage, Chef::Provider::Package::Yum ],
            ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig::Redhat ],

            %w{amazon xcp xenserver ibm_powerkvm cloudlinux parallels} => {
              "3.1.4" => {
    #            service: [ Chef::Resource::RedhatService, Chef::Provider::Service::Redhat ],
              },
            },
            %w{redhat centos scientific oracle} => {
              "7.0" => {
              },
              "6.0" => {
    #            service: [ Chef::Resource::RedhatService, Chef::Provider::Service::Redhat ],
              },
            },
            "fedora" => {
              "15.0" => {
              },
              "14.0" => {
    #            service: [ Chef::Resource::RedhatService, Chef::Provider::Service::Redhat ],
              },
            },
          },

        },

        "freebsd" => {
          "freebsd" => {
            group: [ Chef::Resource::Group, Chef::Provider::Group::Pw ],
            user:  [ Chef::Resource::User::PwUser, Chef::Provider::User::Pw ],

            "freebsd" => {
              "10.3" => {
              },
            },
          },
        },

        "darwin" => {
          %w{mac_os_x mac_os_x_server} => {
            group:   [ Chef::Resource::Group, Chef::Provider::Group::Dscl ],
            package: [ Chef::Resource::HomebrewPackage, Chef::Provider::Package::Homebrew ],
            osx_profile: [ Chef::Resource::OsxProfile, Chef::Provider::OsxProfile],
            user:    [ Chef::Resource::User::DsclUser, Chef::Provider::User::Dscl ],

            "mac_os_x" => {
              "10.9.2" => {
              },
            },
          },
        },

        "windows" => {
          batch:             [ Chef::Resource::Batch, Chef::Provider::Batch ],
          dsc_script:        [ Chef::Resource::DscScript, Chef::Provider::DscScript ],
          env:               [ Chef::Resource::Env, Chef::Provider::Env::Windows ],
          group:             [ Chef::Resource::Group, Chef::Provider::Group::Windows ],
          mount:             [ Chef::Resource::Mount, Chef::Provider::Mount::Windows ],
          package:           [ Chef::Resource::WindowsPackage, Chef::Provider::Package::Windows ],
          powershell_script: [ Chef::Resource::PowershellScript, Chef::Provider::PowershellScript ],
          service:           [ Chef::Resource::WindowsService, Chef::Provider::Service::Windows ],
          user:              [ Chef::Resource::User::WindowsUser, Chef::Provider::User::Windows ],
          windows_package:   [ Chef::Resource::WindowsPackage, Chef::Provider::Package::Windows ],
          windows_service:   [ Chef::Resource::WindowsService, Chef::Provider::Service::Windows ],

          "windows" => {
            %w{mswin mingw32 windows} => {
              "10.9.2" => {
              },
            },
          },
        },

        "aix" => {
          bff_package: [ Chef::Resource::BffPackage, Chef::Provider::Package::Aix ],
          cron: [ Chef::Resource::Cron, Chef::Provider::Cron::Aix ],
          group: [ Chef::Resource::Group, Chef::Provider::Group::Aix ],
          ifconfig: [ Chef::Resource::Ifconfig, Chef::Provider::Ifconfig::Aix ],
          mount: [ Chef::Resource::Mount, Chef::Provider::Mount::Aix ],
          # TODO should be Chef::Resource::BffPackage
          package: [ Chef::Resource::Package, Chef::Provider::Package::Aix ],
          rpm_package: [ Chef::Resource::RpmPackage, Chef::Provider::Package::Rpm ],
          user: [ Chef::Resource::User::AixUser, Chef::Provider::User::Aix ],
    #      service: [ Chef::Resource::AixService, Chef::Provider::Service::Aix ],

          "aix" => {
            "aix" => {
              "5.6" => {
              },
            },
          },
        },

        "hpux" => {
          "hpux" => {
            "hpux" => {
              "3.1.4" => {
                group: [ Chef::Resource::Group, Chef::Provider::Group::Usermod ],
              },
            },
          },
        },

        "netbsd" => {
          "netbsd" => {
            "netbsd" => {
              "3.1.4" => {
                group: [ Chef::Resource::Group, Chef::Provider::Group::Groupmod ],
              },
            },
          },
        },

        "openbsd" => {
          group: [ Chef::Resource::Group, Chef::Provider::Group::Usermod ],
          package: [ Chef::Resource::OpenbsdPackage, Chef::Provider::Package::Openbsd ],

          "openbsd" => {
            "openbsd" => {
              "3.1.4" => {
              },
            },
          },
        },

        "solaris2" => {
          group:           [ Chef::Resource::Group, Chef::Provider::Group::Usermod ],
          ips_package:     [ Chef::Resource::IpsPackage, Chef::Provider::Package::Ips ],
          package:         [ Chef::Resource::SolarisPackage, Chef::Provider::Package::Solaris ],
          mount:           [ Chef::Resource::Mount, Chef::Provider::Mount::Solaris ],
          solaris_package: [ Chef::Resource::SolarisPackage, Chef::Provider::Package::Solaris ],

          "smartos" => {
            smartos_package: [ Chef::Resource::SmartosPackage, Chef::Provider::Package::SmartOS ],
            package:         [ Chef::Resource::SmartosPackage, Chef::Provider::Package::SmartOS ],

            "smartos" => {
              "3.1.4" => {
              },
            },
          },

          "solaris2" => {
            "nexentacore" => {
              "3.1.4" => {
              },
            },
            "omnios" => {
              "3.1.4" => {
                user: [ Chef::Resource::User::SolarisUser, Chef::Provider::User::Solaris ],
              },
            },
            "openindiana" => {
              "3.1.4" => {
              },
            },
            "opensolaris" => {
              "3.1.4" => {
              },
            },
            "solaris2" => {
              user: [ Chef::Resource::User::SolarisUser, Chef::Provider::User::Solaris ],
              "5.11" => {
                package: [ Chef::Resource::IpsPackage, Chef::Provider::Package::Ips ],
              },
              "5.9" => {
              },
            },
          },

        },

        "solaris" => {
          "solaris" => {
            "solaris" => {
              "3.1.4" => {
              },
            },
          },
        },

        "exherbo" => {
          "exherbo" => {
            "exherbo" => {
              "3.1.4" => {
                # TODO should be Chef::Resource::PaludisPackage
                package: [ Chef::Resource::Package, Chef::Provider::Package::Paludis ],
              },
            },
          },
        },
      }

    def self.create_provider_tests(providers, test, expected, filter)
      expected = expected.merge(providers.select { |key, value| key.is_a?(Symbol) })
      providers.each do |key, value|
        if !key.is_a?(Symbol)
          next_test = test.merge({ filter => key })
          next_filter =
            case filter
            when :os
              :platform_family
            when :platform_family
              :platform
            when :platform
              :platform_version
            when :platform_version
              nil
            else
              raise "Hash too deep; only os, platform_family, platform and platform_version supported"
            end
          create_provider_tests(value, next_test, expected, next_filter)
        end
      end
      # If there is no filter, we're as deep as we need to go
      if !filter
        on_platform test.delete(:platform), test do
          expect_providers(expected)
        end
      end
    end

    create_provider_tests(PROVIDERS, {}, {}, :os)
  end
end
