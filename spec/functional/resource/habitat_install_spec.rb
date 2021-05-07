require "spec_helper"
require "chef/mixin/shell_out"

describe Chef::Resource::HabitatInstall do

  let(:bldr) { "https://localhost" }
  let(:tmp_dir) { "/foo/bar" }
  let(:lic) { "accept" }
  let(:version) { "1.5.50" }
  let(:verify_hab) { proc { shell_out!("hab -v").stdout.chomp } }

  describe ":install" do
    include RecipeDSLHelper
    include Chef::Mixin::ShellOut
    context "install habitat" do
      it "installs habitat when missing" do
        habitat_install("clean install") do
          license lic
          bldr_url bldr
          hab_version version
        end.should_be_updated
        expect(verify_hab.call).to eq("1.5.50")
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
