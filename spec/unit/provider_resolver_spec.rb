#
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'spec_helper'
require 'chef/mixin/convert_to_class_name'
require 'chef/provider_resolver'
require 'chef/platform/service_helpers'

include Chef::Mixin::ConvertToClassName

describe Chef::ProviderResolver do

  let(:node) do
    node = Chef::Node.new
    allow(node).to receive(:[]).with(:os).and_return(os)
    allow(node).to receive(:[]).with(:platform_family).and_return(platform_family)
    allow(node).to receive(:[]).with(:platform).and_return(platform)
    allow(node).to receive(:[]).with(:platform_version).and_return(platform_version)
    allow(node).to receive(:is_a?).and_return(Chef::Node)
    node
  end

  let(:provider_resolver) { Chef::ProviderResolver.new(node, resource, action) }

  let(:action) { :start }

  let(:resolved_provider) { provider_resolver.resolve }

  let(:provider) { nil }

  let(:resource_name) { :service }

  let(:resource) { double(Chef::Resource, provider: provider, resource_name: resource_name) }

  before do
    allow(resource).to receive(:is_a?).with(Chef::Resource).and_return(true)
  end

  describe "resolving service resource" do
    def stub_service_providers(*services)
      services ||= []
      allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers)
        .and_return(services)
    end

    def stub_service_configs(*configs)
      configs ||= []
      allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
        .and_return(configs)
    end

    before do
      expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
      allow(resource).to receive(:service_name).and_return("ntp")
    end

    shared_examples_for "an ubuntu platform with upstart, update-rc.d and systemd" do
      before do
        stub_service_providers(:debian, :invokercd, :upstart, :systemd)
      end

      it "when only the SysV init script exists, it returns a Service::Debian provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd, :systemd ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
      end

      it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd, :upstart, :systemd ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
      end

      it "when only the Upstart script exists, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :upstart, :systemd ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
      end

      it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :systemd ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Systemd)
      end
      it "when only the SysV init script exists, it returns a Service::Debian provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Debian)
      end

      it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :initd, :upstart ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
      end

      it "when only the Upstart script exists, it returns a Service::Upstart provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ :upstart ] )
        expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
      end

      it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
        allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
          .and_return( [ ] )
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
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd ] )
        end

        it "enables init, invokercd, debian and upstart providers" do
          expect(provider_resolver.enabled_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
            Chef::Provider::Service::Upstart,
          )
        end

        it "supports all the enabled handlers except for upstart" do
          expect(provider_resolver.supported_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
          )
          expect(provider_resolver.supported_handlers).to_not include(
            Chef::Provider::Service::Upstart,
          )
        end

        it "returns a Service::Debian provider" do
          expect(resolved_provider).to eql(Chef::Provider::Service::Debian)
        end
      end

      # on ubuntu this must be handled by upstart, the init script will exit 1 and fail
      context "when both SysV and Upstart scripts exist" do
        before do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd, :upstart ] )
        end

        it "enables init, invokercd, debian and upstart providers" do
          expect(provider_resolver.enabled_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
            Chef::Provider::Service::Upstart,
          )
        end

        it "supports all the enabled handlers" do
          expect(provider_resolver.supported_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
            Chef::Provider::Service::Upstart,
          )
        end

        it "returns a Service::Upstart provider" do
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end
      end

      # this case is a pure-upstart script which is easy
      context "when only the Upstart script exists" do
        before do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :upstart ] )
        end

        it "enables init, invokercd, debian and upstart providers" do
          expect(provider_resolver.enabled_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
            Chef::Provider::Service::Upstart,
          )
        end

        it "supports only the upstart handler" do
          expect(provider_resolver.supported_handlers).to include(
            Chef::Provider::Service::Upstart,
          )
          expect(provider_resolver.supported_handlers).to_not include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
          )
        end

        it "returns a Service::Upstart provider" do
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end
      end

      # this case is important to get correct for why-run when no config is setup
      context "when both do not exist" do
        before do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ ] )
        end

        it "enables init, invokercd, debian and upstart providers" do
          expect(provider_resolver.enabled_handlers).to include(
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
            Chef::Provider::Service::Upstart,
          )
        end

        it "no providers claim to support the resource" do
          expect(provider_resolver.supported_handlers).to_not include(
            Chef::Provider::Service::Upstart,
            Chef::Provider::Service::Debian,
            Chef::Provider::Service::Init,
            Chef::Provider::Service::Invokercd,
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
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
        end

        it "uses the Service::Insserv Provider when there is no config" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
        end
      end

      context "when the user has installed upstart" do
        before do
          stub_service_providers(:debian, :invokercd, :insserv, :upstart)
        end

        it "when only the SysV init script exists, it returns an Insserv  provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Insserv)
        end

        it "when both SysV and Upstart scripts exist, it returns a Service::Upstart provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :initd, :upstart ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end

        it "when only the Upstart script exists, it returns a Service::Upstart provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ :upstart ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end

        it "when both do not exist, it calls the old style provider resolver and returns a Debian Provider" do
          allow(Chef::Platform::ServiceHelpers).to receive(:config_for_service).with("ntp")
            .and_return( [ ] )
          expect(resolved_provider).to eql(Chef::Provider::Service::Upstart)
        end
      end
    end

    describe "on Ubuntu 14.10" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "14.04" }

      it_behaves_like "an ubuntu platform with upstart, update-rc.d and systemd"
    end

    describe "on Ubuntu 14.04" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "14.04" }

      it_behaves_like "an ubuntu platform with upstart and update-rc.d"
    end

    describe "on Ubuntu 10.04" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "10.04" }

      it_behaves_like "an ubuntu platform with upstart and update-rc.d"
    end

    # old debian uses the Debian provider (does not have insserv or upstart, or update-rc.d???)
    describe "on Debian 4.0" do
      let(:os) { "linux" }
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "4.0" }

      #it_behaves_like "a debian platform using the debian provider"
    end

    # Debian replaced the debian provider with insserv in the FIXME:VERSION distro
    describe "on Debian 7.0" do
      let(:os) { "linux" }
      let(:platform) { "debian" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "7.0" }

      it_behaves_like "a debian platform using the insserv provider"
    end

    %w{solaris2 openindiana opensolaris nexentacore omnios smartos}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "solaris2" }
        let(:platform) { platform }
        let(:platform_family) { platform }
        let(:platform_version) { "5.11" }

        it "returns a Solaris provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Solaris)
        end

        it "always returns a Solaris provider" do
          # no matter what we stub on the next two lines we should get a Solaris provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Solaris)
        end
      end
    end

    %w{mswin mingw32 windows}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "windows" }
        let(:platform) { platform }
        let(:platform_family) { "windows" }
        let(:platform_version) { "5.11" }

        it "returns a Windows provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Windows)
        end

        it "always returns a Windows provider" do
          # no matter what we stub on the next two lines we should get a Windows provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Windows)
        end
      end
    end

    %w{mac_os_x mac_os_x_server}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "darwin" }
        let(:platform) { platform }
        let(:platform_family) { "mac_os_x" }
        let(:platform_version) { "10.9.2" }

        it "returns a Macosx provider" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Macosx)
        end

        it "always returns a Macosx provider" do
          # no matter what we stub on the next two lines we should get a Macosx provider
          stub_service_providers(:debian, :invokercd, :insserv, :upstart, :redhat, :systemd)
          stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
          expect(resolved_provider).to eql(Chef::Provider::Service::Macosx)
        end
      end
    end

    %w{freebsd netbsd}.each do |platform|
      describe "on #{platform}" do
        let(:os) { platform }
        let(:platform) { platform }
        let(:platform_family) { platform }
        let(:platform_version) { "10.0-RELEASE" }

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

        it "foo" do
          stub_service_providers
          stub_service_configs
          expect(resolved_provider).to eql(Chef::Provider::Service::Freebsd)
        end
      end
    end

  end

  describe "for the package provider" do
    let(:resource_name) { :package }

    before do
      expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
    end

    %w{mac_os_x mac_os_x_server}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "darwin" }
        let(:platform) { platform }
        let(:platform_family) { "mac_os_x" }
        let(:platform_version) { "10.9.2" }


        it "returns a Chef::Provider::Package::Homebrew provider" do
          expect(resolved_provider).to eql(Chef::Provider::Package::Homebrew)
        end
      end
    end
  end

  provider_mapping = {
    "mac_os_x" => {
      :package => Chef::Provider::Package::Homebrew,
      :user => Chef::Provider::User::Dscl,
      :group => Chef::Provider::Group::Dscl,
    },
    "mac_os_x_server" => {
      :package => Chef::Provider::Package::Homebrew,
      :user => Chef::Provider::User::Dscl,
      :group => Chef::Provider::Group::Dscl,
    },
    "mswin" => {
      :env =>  Chef::Provider::Env::Windows,
      :user => Chef::Provider::User::Windows,
      :group => Chef::Provider::Group::Windows,
      :mount => Chef::Provider::Mount::Windows,
      :batch => Chef::Provider::Batch,
      :powershell_script => Chef::Provider::PowershellScript,
    },
    "mingw32" => {
      :env =>  Chef::Provider::Env::Windows,
      :user => Chef::Provider::User::Windows,
      :group => Chef::Provider::Group::Windows,
      :mount => Chef::Provider::Mount::Windows,
      :batch => Chef::Provider::Batch,
      :powershell_script => Chef::Provider::PowershellScript,
    },
    "windows" => {
      :env =>  Chef::Provider::Env::Windows,
      :user => Chef::Provider::User::Windows,
      :group => Chef::Provider::Group::Windows,
      :mount => Chef::Provider::Mount::Windows,
      :batch => Chef::Provider::Batch,
      :powershell_script => Chef::Provider::PowershellScript,
    },
    "aix" => {
      :cron => Chef::Provider::Cron::Aix,
    },
    "netbsd"=> {
      :group => Chef::Provider::Group::Groupmod,
    },
    "openbsd" => {
      :group => Chef::Provider::Group::Usermod,
      :package => Chef::Provider::Package::Openbsd,
    },
  }

  def self.do_platform(platform_hash)
    platform_hash.each do |resource, provider|
      describe "for #{resource}" do
        let(:resource_name) { resource }

        it "resolves to a #{provider}" do
          expect(resolved_provider).to eql(provider)
        end
      end
    end
  end

  describe "individual platform mappings" do
    let(:resource_name) { :user }

    before do
      expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
    end

    %w{mac_os_x mac_os_x_server}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "darwin" }
        let(:platform) { platform }
        let(:platform_family) { "mac_os_x" }
        let(:platform_version) { "10.9.2" }

        do_platform(provider_mapping[platform])
      end
    end

    %w{mswin mingw32 windows}.each do |platform|
      describe "on #{platform}" do
        let(:os) { "windows" }
        let(:platform) { platform }
        let(:platform_family) { "windows" }
        let(:platform_version) { "10.9.2" }

        do_platform(provider_mapping[platform])
      end
    end

    describe "on AIX" do
      let(:os) { "aix" }
      let(:platform) { "aix" }
      let(:platform_family) { "aix" }
      let(:platform_version) { "6.2" }

      do_platform(provider_mapping['aix'])
    end

    %w{netbsd openbsd}.each do |platform|
      describe "on #{platform}" do
        let(:os) { platform }
        let(:platform) { platform }
        let(:platform_family) { platform }
        let(:platform_version) { "10.0-RELEASE" }

        do_platform(provider_mapping[platform])
      end
    end
  end

  describe "resolving static providers" do
    def resource_class(resource)
      Chef::Resource.const_get(convert_to_class_name(resource.to_s))
    end
      static_mapping = {
        apt_package:  Chef::Provider::Package::Apt,
        bash: Chef::Provider::Script,
        bff_package: Chef::Provider::Package::Aix,
        breakpoint:  Chef::Provider::Breakpoint,
        chef_gem: Chef::Provider::Package::Rubygems,
        cookbook_file:  Chef::Provider::CookbookFile,
        csh:  Chef::Provider::Script,
        deploy:   Chef::Provider::Deploy::Timestamped,
        deploy_revision:  Chef::Provider::Deploy::Revision,
        directory:  Chef::Provider::Directory,
        dpkg_package: Chef::Provider::Package::Dpkg,
        dsc_script: Chef::Provider::DscScript,
        easy_install_package:  Chef::Provider::Package::EasyInstall,
        erl_call: Chef::Provider::ErlCall,
        execute:  Chef::Provider::Execute,
        file: Chef::Provider::File,
        gem_package: Chef::Provider::Package::Rubygems,
        git:  Chef::Provider::Git,
        homebrew_package: Chef::Provider::Package::Homebrew,
        http_request: Chef::Provider::HttpRequest,
        ips_package: Chef::Provider::Package::Ips,
        link:  Chef::Provider::Link,
        log:  Chef::Provider::Log::ChefLog,
        macports_package:  Chef::Provider::Package::Macports,
        mdadm:  Chef::Provider::Mdadm,
        pacman_package: Chef::Provider::Package::Pacman,
        paludis_package: Chef::Provider::Package::Paludis,
        perl: Chef::Provider::Script,
        portage_package:  Chef::Provider::Package::Portage,
        python: Chef::Provider::Script,
        remote_directory: Chef::Provider::RemoteDirectory,
        route:  Chef::Provider::Route,
        rpm_package:  Chef::Provider::Package::Rpm,
        ruby:  Chef::Provider::Script,
        ruby_block:   Chef::Provider::RubyBlock,
        script:   Chef::Provider::Script,
        smartos_package:  Chef::Provider::Package::SmartOS,
        solaris_package:  Chef::Provider::Package::Solaris,
        subversion:   Chef::Provider::Subversion,
        template:   Chef::Provider::Template,
        timestamped_deploy:  Chef::Provider::Deploy::Timestamped,
        whyrun_safe_ruby_block:  Chef::Provider::WhyrunSafeRubyBlock,
        windows_package:  Chef::Provider::Package::Windows,
        windows_service:  Chef::Provider::Service::Windows,
        yum_package:  Chef::Provider::Package::Yum,
      }

    describe "on Ubuntu 14.04" do
      let(:os) { "linux" }
      let(:platform) { "ubuntu" }
      let(:platform_family) { "debian" }
      let(:platform_version) { "14.04" }

      supported_providers = [
        :apt_package, :bash, :breakpoint, :chef_gem, :cookbook_file, :csh, :deploy,
        :deploy_revision, :directory, :dpkg_package, :easy_install_package, :erl_call,
        :execute, :file, :gem_package, :git, :homebrew_package, :http_request, :link,
        :log, :macports_package, :pacman_package, :paludis_package, :perl, :python,
        :remote_directory, :route, :rpm_package, :ruby, :ruby_block, :script, :subversion,
        :template, :timestamped_deploy, :whyrun_safe_ruby_block, :yum_package,
      ]

      supported_providers.each do |static_resource|
        static_provider = static_mapping[static_resource]
        context "when the resource is a #{static_resource}" do
          let(:resource) { double(Chef::Resource, provider: nil, resource_name: static_resource) }
          let(:action) { :start }  # in reality this doesn't matter much
          it "should resolve to a #{static_provider} provider" do
            expect(provider_resolver).not_to receive(:maybe_chef_platform_lookup)
            expect(resolved_provider).to eql(static_provider)
          end
        end
      end

      unsupported_providers = [
        :bff_package, :dsc_script, :ips_package, :smartos_package,
        :solaris_package, :windows_package, :windows_service,
      ]

      unsupported_providers.each do |static_resource|
        static_provider = static_mapping[static_resource]
        context "when the resource is a #{static_resource}" do
          let(:resource) { double(Chef::Resource, provider: nil, resource_name: static_resource) }
          let(:action) { :start }  # in reality this doesn't matter much
          it "should fall back into the old provider mapper code and hooks" do
            retval = Object.new
            expect(provider_resolver).to receive(:maybe_chef_platform_lookup).and_return(retval)
            expect(resolved_provider).to equal(retval)
          end
        end
      end
    end
  end
end
