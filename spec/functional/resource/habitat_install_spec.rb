require "spec_helper"
require "chef/mixin/shell_out"

describe Chef::Resource::HabitatInstall do
  include Chef::Mixin::ShellOut
  include ChefHTTPShared

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



  let(:bldr) { nil }
  let(:tmp_dir) { nil }
  let(:lic) { nil }
  let(:version) { nil }
  let(:verify_hab) { proc { shell_out!("hab -V").stdout.chomp } }
  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::HabitatInstall.new("clean install", run_context)
    new_resource.license lic
    new_resource.hab_version version if version
    new_resource.tmp_dir tmp_dir if tmp_dir
    new_resource.bldr_url bldr if bldr
    new_resource
  end

  describe ":install" do
    include RecipeDSLHelper
    include Chef::Mixin::ShellOut
    let(:bldr) { "https://bldr.habitat.sh" }
    let(:lic) { "accept" }
    let(:version) { "1.5.50" }

    context "install habitat" do
      it "installs habitat when missing" do
        subject.run_action(:install)
        expect(subject).to be_updated_by_last_action
        expect(verify_hab.call).to include("1.5.50")
      end
    end

    context "install habitat idempotent" do
      it "not install habitat when installed" do
        subject.run_action(:install)
        expect(subject).to not_be_updated_by_last_action
      end
    end

    context "update habitat" do
      it "updates habitat when already installed" do
        subject.run_action(:update)
        expect(subject).to be_updated_by_last_action
        expect(verify_hab.call).to include("1.6")
      end
    end
    # it 'installs habitat with a depot url' do
    #   expect(chef_run).to install_habitat_install('install habitat with depot url')
    #     .with(bldr_url: 'https://localhost')
    # end

    # it 'installs habitat with tmp_dir' do
    #   expect(chef_run).to install_habitat_install('install habitat with tmp_dir')
    #     .with(tmp_dir: '/foo/bar')
    # end
  end
end
