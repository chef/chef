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

# Open up Provider so we can write things down easier in here
#module Chef::Provider

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

  def self.on_platform(platform, *tags,
    platform_version: '11.0.1',
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
    providers.each do |name, provider|
      describe name.to_s do
        let(:resource_name) { name }
        if provider
          it "resolves to a #{provider}" do
            expect(resolved_provider).to eql(provider)
          end
        else
          it "Fails to resolve (since #{name.inspect} is unsupported on #{platform} #{platform_version})" do
            expect { resolved_provider }.to raise_error /Cannot find a provider/
          end
        end
      end
    end
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
        stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
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
        stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
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
        stub_service_configs(:initd, :upstart, :xinetd, :user_local_etc_rcd, :systemd)
        expect(resolved_provider).to eql(Chef::Provider::Service::Macosx)
      end
    end

    on_platform %w(freebsd netbsd), platform_version: '3.1.4' do
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

  PROVIDERS =
  {
    bash: Chef::Provider::Script,
    breakpoint: Chef::Provider::Breakpoint,
    chef_gem: Chef::Provider::Package::Rubygems,
    cookbook_file: Chef::Provider::CookbookFile,
    csh: Chef::Provider::Script,
    deploy: Chef::Provider::Deploy::Timestamped,
    deploy_revision: Chef::Provider::Deploy::Revision,
    directory: Chef::Provider::Directory,
    easy_install_package: Chef::Provider::Package::EasyInstall,
    erl_call: Chef::Provider::ErlCall,
    execute: Chef::Provider::Execute,
    file: Chef::Provider::File,
    gem_package: Chef::Provider::Package::Rubygems,
    git: Chef::Provider::Git,
    group: Chef::Provider::Group::Gpasswd,
    homebrew_package: Chef::Provider::Package::Homebrew,
    http_request: Chef::Provider::HttpRequest,
    ifconfig: Chef::Provider::Ifconfig,
    link: Chef::Provider::Link,
    log: Chef::Provider::Log::ChefLog,
    macports_package: Chef::Provider::Package::Macports,
    mdadm: Chef::Provider::Mdadm,
    mount: Chef::Provider::Mount::Mount,
    perl: Chef::Provider::Script,
    portage_package: Chef::Provider::Package::Portage,
    python: Chef::Provider::Script,
    remote_directory: Chef::Provider::RemoteDirectory,
    route: Chef::Provider::Route,
    ruby: Chef::Provider::Script,
    ruby_block: Chef::Provider::RubyBlock,
    script: Chef::Provider::Script,
    subversion: Chef::Provider::Subversion,
    template: Chef::Provider::Template,
    timestamped_deploy: Chef::Provider::Deploy::Timestamped,
    user: Chef::Provider::User::Useradd,
    whyrun_safe_ruby_block: Chef::Provider::WhyrunSafeRubyBlock,

    # We want to check that these are unsupported:
    apt_package: nil,
    bff_package: nil,
    dsc_script: nil,
    dpkg_package: nil,
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
      apt_package: Chef::Provider::Package::Apt,
      dpkg_package: Chef::Provider::Package::Dpkg,
      pacman_package: Chef::Provider::Package::Pacman,
      paludis_package: Chef::Provider::Package::Paludis,
      rpm_package: Chef::Provider::Package::Rpm,
      yum_package: Chef::Provider::Package::Yum,

      "debian" => {
        ifconfig: Chef::Provider::Ifconfig::Debian,
        package: Chef::Provider::Package::Apt,
#        service: Chef::Provider::Service::Debian,

        "debian" => {
          "7.0" => {
          },
          "6.0" => {
            ifconfig: Chef::Provider::Ifconfig,
#            service: Chef::Provider::Service::Insserv,
          },
          "5.0" => {
            ifconfig: Chef::Provider::Ifconfig,
          },
        },
        "gcel" => {
          "3.1.4" => {
            ifconfig: Chef::Provider::Ifconfig,
          },
        },
        "linaro" => {
          "3.1.4" => {
            ifconfig: Chef::Provider::Ifconfig,
          },
        },
        "linuxmint" => {
          "3.1.4" => {
            ifconfig: Chef::Provider::Ifconfig,
#            service: Chef::Provider::Service::Upstart,
          },
        },
        "raspbian" => {
          "3.1.4" => {
            ifconfig: Chef::Provider::Ifconfig,
          },
        },
        "ubuntu" => {
          "11.10" => {
          },
          "10.04" => {
            ifconfig: Chef::Provider::Ifconfig,
          },
        },
      },

      "arch" => {
        package: Chef::Provider::Package::Pacman,

        "arch" => {
          "3.1.4" => {
          }
        },
      },

      "freebsd" => {
        group: Chef::Provider::Group::Pw,
        user: Chef::Provider::User::Pw,

        "freebsd" => {
          "3.1.4" => {
          },
        },
      },
      "suse" => {
        group: Chef::Provider::Group::Gpasswd,
        "suse" => {
          "12.0" => {
          },
          %w(11.1 11.2 11.3) => {
            group: Chef::Provider::Group::Suse,
          },
        },
        "opensuse" => {
#          service: Chef::Provider::Service::Redhat,
          package: Chef::Provider::Package::Zypper,
          group: Chef::Provider::Group::Usermod,
          "12.3" => {
          },
          "12.2" => {
            group: Chef::Provider::Group::Suse,
          },
        },
      },

      "gentoo" => {
        package: Chef::Provider::Package::Portage,
        portage_package: Chef::Provider::Package::Portage,
#        service: Chef::Provider::Service::Gentoo,

        "gentoo" => {
          "3.1.4" => {
          },
        },
      },

      "rhel" => {
#        service: Chef::Provider::Service::Systemd,
        package: Chef::Provider::Package::Yum,
        ifconfig: Chef::Provider::Ifconfig::Redhat,

        %w(amazon xcp xenserver ibm_powerkvm cloudlinux parallels) => {
          "3.1.4" => {
#            service: Chef::Provider::Service::Redhat,
          },
        },
        %w(redhat centos scientific oracle) => {
          "7.0" => {
          },
          "6.0" => {
#            service: Chef::Provider::Service::Redhat,
          },
        },
        "fedora" => {
          "15.0" => {
          },
          "14.0" => {
#            service: Chef::Provider::Service::Redhat,
          },
        },
      },

    },

    "darwin" => {
      %w(mac_os_x mac_os_x_server) => {
        group:   Chef::Provider::Group::Dscl,
        package: Chef::Provider::Package::Homebrew,
        user:    Chef::Provider::User::Dscl,

        "mac_os_x" => {
          "10.9.2" => {
          },
        },
      },
    },

    "windows" => {
      batch: Chef::Provider::Batch,
      dsc_script: Chef::Provider::DscScript,
      env: Chef::Provider::Env::Windows,
      group: Chef::Provider::Group::Windows,
      mount: Chef::Provider::Mount::Windows,
      package: Chef::Provider::Package::Windows,
      powershell_script: Chef::Provider::PowershellScript,
      service: Chef::Provider::Service::Windows,
      user: Chef::Provider::User::Windows,
      windows_package: Chef::Provider::Package::Windows,
      windows_service: Chef::Provider::Service::Windows,

      "windows" => {
        %w(mswin mingw32 windows) => {
          "10.9.2" => {
          },
        },
      },
    },

    "aix" => {
      bff_package: Chef::Provider::Package::Aix,
      cron: Chef::Provider::Cron::Aix,
      group: Chef::Provider::Group::Aix,
      ifconfig: Chef::Provider::Ifconfig::Aix,
      mount: Chef::Provider::Mount::Aix,
      package: Chef::Provider::Package::Aix,
      rpm_package: Chef::Provider::Package::Rpm,
      user: Chef::Provider::User::Aix,
#      service: Chef::Provider::Service::Aix,

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
            group: Chef::Provider::Group::Usermod
          }
        }
      }
    },

    "netbsd" => {
      "netbsd" => {
        "netbsd" => {
          "3.1.4" => {
            group: Chef::Provider::Group::Groupmod,
          },
        },
      },
    },

    "openbsd" => {
      group: Chef::Provider::Group::Usermod,
      package: Chef::Provider::Package::Openbsd,

      "openbsd" => {
        "openbsd" => {
          "3.1.4" => {
          },
        },
      },
    },

    "solaris2" => {
      group: Chef::Provider::Group::Usermod,
      ips_package: Chef::Provider::Package::Ips,
      package: Chef::Provider::Package::Ips,
      mount: Chef::Provider::Mount::Solaris,
      solaris_package: Chef::Provider::Package::Solaris,

      "smartos" => {
        smartos_package: Chef::Provider::Package::SmartOS,
        package: Chef::Provider::Package::SmartOS,

        "smartos" => {
          "3.1.4" => {
          },
        },
      },

      "solaris2" => {
        "nexentacore" => {
          "3.1.4" => {
            package: Chef::Provider::Package::Solaris,
          },
        },
        "omnios" => {
          "3.1.4" => {
            user: Chef::Provider::User::Solaris,
          }
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
          user: Chef::Provider::User::Solaris,
          "5.11" => {
          },
          "5.9" => {
            package: Chef::Provider::Package::Solaris,
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
            package: Chef::Provider::Package::Paludis
          }
        }
      }
    }
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
