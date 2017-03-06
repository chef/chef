require "spec_helper"
require "chef/provider/package/windows/registry_uninstall_entry"

describe Chef::Provider::Package::Windows::RegistryUninstallEntry do
  let(:hkey) { :hkey } # mock all the methods
  let(:key) { :key }
  let(:entry) { { "UninstallString" => "UninstallStringPath", "QuietUninstallString" => "QuietUninstallStringPath" } }

  describe "when QuietUninstallString key not present" do
    let(:quiet_uninstall_string) { nil }
    let (:quiet_uninstall_string_key) { Chef::Provider::Package::Windows::RegistryUninstallEntry.quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry).uninstall_string }
    it "should return UninstallString key value" do
      expect(quiet_uninstall_string_key).to eql "UninstallStringPath"
    end
  end

  describe "when QuietUninstallString key present" do
    let(:quiet_uninstall_string) { "QuietUninstallString" }
    let (:quiet_uninstall_string_key) { Chef::Provider::Package::Windows::RegistryUninstallEntry.quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry).uninstall_string }

    it "should return QuietUninstallString key value" do
      expect(quiet_uninstall_string_key).to eql "QuietUninstallStringPath"
    end
  end
end
