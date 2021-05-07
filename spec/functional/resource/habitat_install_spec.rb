require "spec_helper"

describe Chef::Resource::HabitatInstall do

  let(:bldr_url) { "https://localhost" }
  let(:tmp_dir) { "/foo/bar" }
  let(:license) { "accept" }
  let(:hab_version) { "1.5.50" }
  let(:verify_hab) { proc { shell_out!("hab -v").stdout.chomp } }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::HabitatInstall.new("test habitat install", run_context)
    new_resource.tmp_dir tmp_dir
    new_resource.hab_version hab_version
    new_resource.license license
    new_resource.bldr_url bldr_url
    new_resource
  end

  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end

  before(:all) do
    ENV["Path"] = ENV.delete("Path")
  end

  context "install habitat" do
    it "installs habitat" do
      subject.run_action(:install)
      expect(verify_hab.call).to eq("1.5.50")
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
