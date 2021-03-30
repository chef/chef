require "spec_helper"

require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"
require "chef-utils/dist"

describe "chef-client with compliance phase" do

  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.join(__dir__, "..", "..", "..") }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "bundle exec #{ChefUtils::Dist::Infra::CLIENT} --minimal-ohai" }

  when_the_repository "has a custom profile" do
    let(:report_file) { path_to("report_file.json") }

    before do
      directory "profiles/my-profile" do
        file "inspec.yml", <<~FILE
          ---
          name: my-profile
        FILE

        directory "controls" do
          file "my_control.rb", <<~FILE
            control "my control" do
              describe Dir.home do
                it { should be_kind_of String }
              end
            end
          FILE
        end
      end

      file "attributes.json", <<~FILE
        {
          "audit": {
            "compliance_phase": true,
            "json_file": {
              "location": "#{report_file}"
            },
            "profiles": {
              "my-profile": {
                "path": "#{path_to("profiles/my-profile")}"
              }
            }
          }
        }
      FILE
    end

    it "should complete with success" do
      result = shell_out!("#{chef_client} --local-mode --json-attributes #{path_to("attributes.json")}", cwd: chef_dir)
      result.error!

      inspec_report = JSON.parse(File.read(report_file))
      expect(inspec_report["profiles"].length).to eq(1)

      profile = inspec_report["profiles"].first
      expect(profile["name"]).to eq("my-profile")
      expect(profile["controls"].length).to eq(1)

      control = profile["controls"].first
      expect(control["id"]).to eq("my control")
      expect(control["results"].length).to eq(1)

      result = control["results"].first
      expect(result["status"]).to eq("passed")
    end
  end
end
