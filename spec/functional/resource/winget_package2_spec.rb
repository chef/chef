require "spec_helper"
require "chef/mixin/powershell_exec"
require "chef/resource/hostname"
describe Chef::Resource::Hostname, :windows_only do
  include Chef::Mixin::PowershellExec

  def get_domain_status
    powershell_exec!("(Get-WmiObject -Class Win32_ComputerSystem).PartofDomain").result
  end

  let(:package_name) { "7zip" }
  let(:package_name2) { "pennywise" }
  let(:package_version) { nil }
  let(:source_name) { "winget" }
  let(:scope) { "user" }
  let(:options) { nil }
  let(:force) { nil }

  # let(:run_context) do
  #   node = Chef::Node.new
  #   node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
  #   node.automatic["os"] = "windows"
  #   node.automatic["platform"] = "windows"
  #   node.automatic["platform_version"] = "6.1"
  #   node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
  #   empty_events = Chef::EventDispatch::Dispatcher.new
  #   Chef::RunContext.new(node, {}, empty_events)
  # end

  # subject do
  #   new_resource = Chef::Resource::WingetPackage.new("Winget", run_context)
  #   new_resource
  # end

  # let(:provider) do
  #   provider = subject.provider_for_action(subject.action)
  #   provider
  # end

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  let(:winget_package) do
    r = Chef::Resource::WingetPackage.new(package_name, run_context)
    r
  end


  describe "Installing packages" do
    context "Installing various Windows packages" do
      it "installs a single windows package" do
        winget_package.package_name package_name2
        winget_package.run_action(:install)
        expect(winget_package).to be_updated_by_last_action
      end
    end

  end
end