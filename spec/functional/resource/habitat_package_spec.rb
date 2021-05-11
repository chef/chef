require "spec_helper"
require "chef/mixin/shell_out"

describe Chef::Resource::HabitatPackage do
  include Chef::Mixin::ShellOut
  let(:file_cache_path) { Dir.mktmpdir }

  before(:each) do
    @old_file_cache = Chef::Config[:file_cache_path]
    Chef::Config[:file_cache_path] = file_cache_path
    Chef::Config[:rest_timeout] = 2
    Chef::Config[:http_retry_delay] = 1
    Chef::Config[:http_retry_count] = 2
  end

  after(:each) do
    Chef::Config[:file_cache_path] = @old_file_cache
    FileUtils.rm_rf(file_cache_path)
  end

  let(:binlink) { nil }
  let(:package_name) { "core/redis" }
  let(:lic) { nil }
  let(:bldr_url) { nil }
  let(:channel) { nil }
  let(:auth_token) { nil }
  let(:options) { nil }
  let(:keep_latest) { nil }
  let(:no_deps) { nil }
  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end
  let(:verify_toml) { proc { shell_out!("ls -a /hab/sup/default/config/").stdout.chomp } }
  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::HabitatPackage.new(package_name, run_context)
    new_resource.bldr_url bldr_url if bldr_url
    new_resource.channel channel if channel
    new_resource.auth_token auth_token if auth_token
    new_resource.binlink binlink if binlink
    new_resource
  end

  describe ":install" do
    include RecipeDslHelper

    context "Installs habitat packages" do

      it "installs habitat" do
        habitat_install("new") do
          license "accept"
        end.should_be_updated
      end

      it "installs core/redis" do
        subject.run_action(:run)
        expect(subject).to be_updated_by_last_action
      end

      it "installs core/bundler with specified version" do
        habitat_package("core/bundler") do
          version "1.13.3/20161011123917"
        end.should_be_updated
      end

      it "installs lamont-granquist/ruby with a specific version" do
        habitat_package("lamanot-granquist/ruby") do
          version "2.3.1"
        end.should_be_updated
      end

      it "installs core/hab-sup with a specific depot url" do
        habitat_package("core/hab_sup") do
          bldr_url "https://bldr.habitat.sh"
        end.should_be_updated
      end

      it "installs core/jq-static with forced binlink" do
        habitat_package("core/jq-static") do
          binlink :force
        end.should_be_updated
      end
    end
  end
end
