require "spec_helper"

describe Chef::Resource::RegistryKey do
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:node) { Chef::Node.new }
  let(:ohai) { Ohai::System.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::RegistryKey.new("HKCU\\Software", run_context)}

  let(:parent) { "Opscode" }
  let(:child) { "Whatever"}
  let(:key_parent) { "Software\\#{parent}" }
  let(:key_child) { "#{key_parent}}\\#{child}" }
  let(:reg_parent) { "HKLM\\#{key_parent}" }
  let(:reg_child) { "HKLM\\#{key_child}" }
  let(:hive_class) { ::Win32::Registry::HKEY_LOCAL_MACHINE }
  let(:resource_name) { "This is the name of my Resource" }

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:registry) { Chef::Win32::Registry.new(run_context) }

  before do
    events
    node
    ohai
    ohai.all_plugins
    node.consume_external_attrs(ohai.data, {})
    run_context
  end

  context "when running on non-Windows", :unix_only do
    let(:registry_key) { "HKCU\\Software\\Opscode" }
    let(:registry_key_values) { [{name: "Color", type: :string, data: "Orange"}]}
    subject do
      resource.key(registry_key)
      resource.values(registry_key_values)
      resource.run_action(:create)
    end
    it "raise an exception because we don't have a windows registry on non-Windows" do
      expect { subject }.to raise_error(Chef::Exceptions::Win32NotWindows)
    end
  end

  context "when running on Windows", :windows_only do
    context "action :create" do
      before { reset_registry }
    end
  end
end