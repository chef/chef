require "spec_helper"
require "chef/mixin/shell_out"

describe Chef::Resource::HabitatSup do
  include Chef::Mixin::ShellOut
  include ChefHTTPShared

  let(:file_cache_path) { Dir.mktmpdir }

  before(:each) do
    @old_file_cache = Chef::Config[:file_cache_path]
    Chef::Config[:file_cache_path] = file_cache_path
    Chef::Config[:rest_timeout] = 2
    Chef::Config[:http_retry_delay] = 1
    Chef::Config[:http_retry_count] = 2
    allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return([:systemd])
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with("/hab").and_return(true)
    allow(Dir).to receive(:exist?).with("/hab/sup/default/config").and_return(true)
  end

  after(:each) do
    Chef::Config[:file_cache_path] = @old_file_cache
    FileUtils.rm_rf(file_cache_path)
  end

  let(:toml_config) { nil }
  let(:lic) { nil }
  let(:listen_http) { "0.0.0.0:9999" }
  let(:listen_gossip) { "0.0.0.0:9998" }
  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::HabitatSup.new("install supervisor with toml_config", run_context)
    new_resource.license lic
    new_resource.toml_config toml_config if toml_config
    new_resource.listen_http listen_http
    new_resource.listen_gossip listen_gossip
  end

  describe ":run" do
    include RecipeDSLHelper
    let(:lic) { "accept" }
    let(:toml_config) { true }
    let(:file) { "/hab/sup/default/config/sup.toml" }

    context "When toml_config flag is set to true for hab_sup" do

      it "installs habitat" do
        habitat_install("new") do
          license "accept"
        end.should_be_updated
      end

      it "installs supervisor with toml configuration file" do
        subject.run_action(:run)
        expect(subject).to be_updated_by_last_action
        expect(subject).to create_directory("/hab/sup/default/config")
        expect(file).to be_an_existing_file
      end
    end
  end
end
