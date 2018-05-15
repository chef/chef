require "spec_helper"
require "chef/provider/package/windows/registry_uninstall_entry"

describe Chef::Provider::Package::Windows::RegistryUninstallEntry do
  let(:hkey) { :hkey } # mock all the methods
  let(:key) { :key }
  let(:entry) { { "UninstallString" => "UninstallStringPath", "QuietUninstallString" => "QuietUninstallStringPath" } }

  describe "when QuietUninstallString key not present" do
    let(:quiet_uninstall_string) { nil }
    let (:quiet_uninstall_string_key) { Chef::Provider::Package::Windows::RegistryUninstallEntry.quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry).uninstall_string }
    it "returns UninstallString key value" do
      expect(quiet_uninstall_string_key).to eql "UninstallStringPath"
    end
  end

  describe "when QuietUninstallString key present" do
    let(:quiet_uninstall_string) { "QuietUninstallString" }
    let (:quiet_uninstall_string_key) { Chef::Provider::Package::Windows::RegistryUninstallEntry.quiet_uninstall_string_key?(quiet_uninstall_string, hkey, key, entry).uninstall_string }
    it "returns QuietUninstallString key value" do
      expect(quiet_uninstall_string_key).to eql "QuietUninstallStringPath"
    end
  end

  describe ".find_entries", :windows_only do
    let (:registry_uninstall_entry) { Chef::Provider::Package::Windows::RegistryUninstallEntry }
    before(:each) do
      allow_any_instance_of(::Win32::Registry).to receive(:open).and_return("::Win32::Registry::HKEY_CURRENT_USER")
    end

    context "when passing nil" do
      let(:package_name) { nil }
      it "returns empty entries array" do
        allow(Chef::Provider::Package::Windows::RegistryUninstallEntry).to receive(:read_registry_property).and_return(nil)
        entries = Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries(package_name)
        expect(entries.size).to eql 0
      end
    end

    context "when passing empty string" do
      let(:package_name) { " " }
      it "returns no entries" do
        allow(Chef::Provider::Package::Windows::RegistryUninstallEntry).to receive(:read_registry_property).and_return(nil)
        entries = Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries(package_name)
        expect(entries.size).to eql 0
      end
    end

    context "when package is not found" do
      let(:package_name) { "hive" }
      it "returns no entries" do
        allow(Chef::Provider::Package::Windows::RegistryUninstallEntry).to receive(:read_registry_property).and_return("Chef Client")
        entries = Chef::Provider::Package::Windows::RegistryUninstallEntry.find_entries(package_name)
        expect(entries).to eql []
      end
    end

    context "when trailing spaces are given in display name" do
      let(:package_name) { "Chef" }
      let(:display_name_with_space) { "Chef      " }
      it "removes the trailing spaces" do
        allow(Chef::Provider::Package::Windows::RegistryUninstallEntry).to receive(:read_registry_property).and_return(display_name_with_space)
        entries = registry_uninstall_entry.find_entries(package_name).first
        expect(entries.display_name.rstrip).to eql package_name
      end
    end

    context "When package found successfully" do
      let(:package_name) { "Chef Client" }
      let(:display_name) { "Chef Client" }
      it "returns 'Chef Client' entries" do
        allow(Chef::Provider::Package::Windows::RegistryUninstallEntry).to receive(:read_registry_property).and_return(display_name)
        entries = registry_uninstall_entry.find_entries(package_name).first
        expect(entries.display_name.rstrip).to eql package_name
      end
    end
  end
end
