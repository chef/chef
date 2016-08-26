#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright 2015-2016, Chef, Inc.
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

describe Chef::Provider::OsxProfile do
  let(:shell_out_success) do
    double("shell_out", :exitstatus => 0, :error? => false)
  end
  describe "action_create" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:new_resource) { Chef::Resource::OsxProfile.new("Profile Test", run_context) }
    let(:provider) { Chef::Provider::OsxProfile.new(new_resource, run_context) }
    let(:all_profiles) do
      { "_computerlevel" => [{ "ProfileDisplayName" => "Finder Settings",
                               "ProfileIdentifier" => "com.apple.finder",
                               "ProfileInstallDate" => "2015-11-08 23:15:21 +0000",
                               "ProfileItems" => [{ "PayloadContent" => { "PayloadContentManagedPreferences" => { "com.apple.finder" => { "Forced" => [{ "mcx_preference_settings" => { "ShowExternalHardDrivesOnDesktop" => false } }] } } },
                                                    "PayloadDisplayName" => "Custom: (com.apple.finder)",
                                                    "PayloadIdentifier" => "com.apple.finder",
                                                    "PayloadType" => "com.apple.ManagedClient.preferences",
                                                    "PayloadUUID" => "a017048f-684b-4e81-baa3-43afe316d739",
                                                    "PayloadVersion" => 1 }],
                               "ProfileOrganization" => "Chef",
                               "ProfileRemovalDisallowed" => "false",
                               "ProfileType" => "Configuration",
                               "ProfileUUID" => "e2e09bef-e673-44a6-bcbe-ecb5f1c1b740",
                               "ProfileVerificationState" => "unsigned",
                               "ProfileVersion" => 1 },
        { "ProfileDisplayName" => "ScreenSaver Settings",
          "ProfileIdentifier" => "com.testprofile.screensaver",
          "ProfileInstallDate" => "2015-10-05 23:15:21 +0000",
          "ProfileItems" => [{ "PayloadContent" => { "PayloadContentManagedPreferences" => { "com.apple.screensaver" => { "Forced" => [{ "mcx_preference_settings" => { "idleTime" => 0 } }] } } },
                               "PayloadDisplayName" => "Custom: (com.apple.screensaver)",
                               "PayloadIdentifier" => "com.apple.screensaver",
                               "PayloadType" => "com.apple.ManagedClient.preferences",
                               "PayloadUUID" => "73fc30e0-1e57-0131-c32d-000c2944c110",
                               "PayloadVersion" => 1 }],
          "ProfileOrganization" => "Chef",
          "ProfileRemovalDisallowed" => "false",
          "ProfileType" => "Configuration",
          "ProfileUUID" => "6e95927c-f200-54b4-85c7-52ab99b61c47",
          "ProfileVerificationState" => "unsigned",
          "ProfileVersion" => 1 }],
      }
    end
      # If anything is changed within this profile, be sure to update the
      # ProfileUUID in all_profiles to match the new config specific UUID
    let(:test_profile) do
      {
        "PayloadIdentifier" => "com.testprofile.screensaver",
        "PayloadRemovalDisallowed" => false,
        "PayloadScope" => "System",
        "PayloadType" => "Configuration",
        "PayloadUUID" => "1781fbec-3325-565f-9022-8aa28135c3cc",
        "PayloadOrganization" => "Chef",
        "PayloadVersion" => 1,
        "PayloadDisplayName" => "Screensaver Settings",
        "PayloadContent" => [
          {
            "PayloadType" => "com.apple.ManagedClient.preferences",
            "PayloadVersion" => 1,
            "PayloadIdentifier" => "com.testprofile.screensaver",
            "PayloadUUID" => "73fc30e0-1e57-0131-c32d-000c2944c108",
            "PayloadEnabled" => true,
            "PayloadDisplayName" => "com.apple.screensaver",
            "PayloadContent" => {
              "com.apple.screensaver" => {
                "Forced" => [
                  {
                    "mcx_preference_settings" => {
                      "idleTime" => 0,
                    },
                  },
                ],
              },
            },
          },
        ],
        }
    end
    let(:no_profiles) do
      {}
    end

    before(:each) do
      allow(provider).to receive(:cookbook_file_available?).and_return(true)
      allow(provider).to receive(:cache_cookbook_profile).and_return("/tmp/test.mobileconfig.remote")
      allow(provider).to receive(:get_new_profile_hash).and_return(test_profile)
      allow(provider).to receive(:get_installed_profiles).and_return(all_profiles)
      allow(provider).to receive(:read_plist).and_return(all_profiles)
      allow(::File).to receive(:unlink).and_return(true)
    end

    it "should build the get all profiles shellout command correctly" do
      profile_name = "com.testprofile.screensaver.mobileconfig"
      tempfile = "/tmp/allprofiles.plist"
      new_resource.profile_name profile_name
      allow(provider).to receive(:generate_tempfile).and_return(tempfile)
      allow(provider).to receive(:get_installed_profiles).and_call_original
      allow(provider).to receive(:read_plist).and_return(all_profiles)
      expect(provider).to receive(:shell_out!).with("profiles -P -o '/tmp/allprofiles.plist'")
      provider.load_current_resource
    end

    it "should use profile name as profile when no profile is set" do
      profile_name = "com.testprofile.screensaver.mobileconfig"
      new_resource.profile_name profile_name
      provider.load_current_resource
      expect(new_resource.profile_name).to eql(profile_name)
    end

    it "should use identifier from specified profile" do
      new_resource.profile test_profile
      provider.load_current_resource
      expect(
        provider.instance_variable_get(:@new_profile_identifier)
        ).to eql(test_profile["PayloadIdentifier"])
    end

    it "should install when not installed" do
      new_resource.profile test_profile
      allow(provider).to receive(:get_installed_profiles).and_return(no_profiles)
      provider.load_current_resource
      expect { provider.run_action(:install) }.to_not raise_error
    end

    it "does not install if the profile is already installed" do
      new_resource.profile test_profile
      allow(provider).to receive(:get_installed_profiles).and_return(all_profiles)
      provider.load_current_resource
      expect(provider).to_not receive(:install_profile)
      expect { provider.action_install }.to_not raise_error
    end

    it "should install when installed but uuid differs" do
      new_resource.profile test_profile
      all_profiles["_computerlevel"][1]["ProfileUUID"] = "1781fbec-3325-565f-9022-9bb39245d4dd"
      provider.load_current_resource
      expect { provider.run_action(:install) }.to_not raise_error
    end

    it "should build the shellout install command correctly" do
      profile_path = "/tmp/test.mobileconfig"
      new_resource.profile test_profile
      # Change the profile so it triggers an install
      all_profiles["_computerlevel"][1]["ProfileUUID"] = "1781fbec-3325-565f-9022-9bb39245d4dd"
      provider.load_current_resource
      allow(provider).to receive(:write_profile_to_disk).and_return(profile_path)
      expect(provider).to receive(:shell_out).with("profiles -I -F '#{profile_path}'").and_return(shell_out_success)
      provider.action_install()
    end

    it "should fail if there is no identifier inside the profile" do
      test_profile.delete("PayloadIdentifier")
      new_resource.profile test_profile
      error_message = "The specified profile does not seem to be valid"
      expect { provider.run_action(:install) }.to raise_error(RuntimeError, error_message)
    end

  end

  describe "action_remove" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:new_resource) { Chef::Resource::OsxProfile.new("Profile Test", run_context) }
    let(:provider) { Chef::Provider::OsxProfile.new(new_resource, run_context) }
    let(:current_resource) { Chef::Resource::OsxProfile.new("Profile Test") }
    let(:all_profiles) do
      { "_computerlevel" => [{ "ProfileDisplayName" => "ScreenSaver Settings",
                               "ProfileIdentifier" => "com.apple.screensaver",
                               "ProfileInstallDate" => "2015-10-05 23:15:21 +0000",
                               "ProfileItems" => [{ "PayloadContent" => { "PayloadContentManagedPreferences" => { "com.apple.screensaver" => { "Forced" => [{ "mcx_preference_settings" => { "idleTime" => 0 } }] } } },
                                                    "PayloadDisplayName" => "Custom: (com.apple.screensaver)",
                                                    "PayloadIdentifier" => "com.apple.screensaver",
                                                    "PayloadType" => "com.apple.ManagedClient.preferences",
                                                    "PayloadUUID" => "73fc30e0-1e57-0131-c32d-000c2944c108",
                                                    "PayloadVersion" => 1 }],
                               "ProfileOrganization" => "Chef",
                               "ProfileRemovalDisallowed" => "false",
                               "ProfileType" => "Configuration",
                               "ProfileUUID" => "1781fbec-3325-565f-9022-8aa28135c3cc",
                               "ProfileVerificationState" => "unsigned",
                               "ProfileVersion" => 1 },
        { "ProfileDisplayName" => "ScreenSaver Settings",
          "ProfileIdentifier" => "com.testprofile.screensaver",
          "ProfileInstallDate" => "2015-10-05 23:15:21 +0000",
          "ProfileItems" => [{ "PayloadContent" => { "PayloadContentManagedPreferences" => { "com.apple.screensaver" => { "Forced" => [{ "mcx_preference_settings" => { "idleTime" => 0 } }] } } },
                               "PayloadDisplayName" => "Custom: (com.apple.screensaver)",
                               "PayloadIdentifier" => "com.apple.screensaver",
                               "PayloadType" => "com.apple.ManagedClient.preferences",
                               "PayloadUUID" => "73fc30e0-1e57-0131-c32d-000c2944c110",
                               "PayloadVersion" => 1 }],
          "ProfileOrganization" => "Chef",
          "ProfileRemovalDisallowed" => "false",
          "ProfileType" => "Configuration",
          "ProfileUUID" => "1781fbec-3325-565f-9022-8aa28135c3cc",
          "ProfileVerificationState" => "unsigned",
          "ProfileVersion" => 1 }],
      }
    end
    before(:each) do
      provider.current_resource = current_resource
      allow(provider).to receive(:get_installed_profiles).and_return(all_profiles)
    end

    it "should use resource name for identifier when not specified" do
      new_resource.profile_name "com.testprofile.screensaver"
      new_resource.action(:remove)
      provider.load_current_resource
      expect(provider.instance_variable_get(:@new_profile_identifier)
        ).to eql(new_resource.profile_name)
    end

    it "should use specified identifier" do
      new_resource.identifier "com.testprofile.screensaver"
      new_resource.action(:remove)
      provider.load_current_resource
      expect(provider.instance_variable_get(:@new_profile_identifier)
        ).to eql(new_resource.identifier)
    end

    it "should work with spaces in the identifier" do
      provider.action = :remove
      provider.define_resource_requirements
      expect { provider.process_resource_requirements }.not_to raise_error
    end

    it "should build the shellout remove command correctly" do
      new_resource.identifier "com.testprofile.screensaver"
      new_resource.action(:remove)
      provider.load_current_resource
      expect(provider).to receive(:shell_out).with("profiles -R -p '#{new_resource.identifier}'").and_return(shell_out_success)
      provider.action_remove()
    end
  end
end
