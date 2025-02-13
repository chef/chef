require "spec_helper"

describe Chef::Resource::RegistryKey do
  class ::Chef::Resource::RegistryKey
    # for test purposes only, don't scrub the values
    def scrub_values(values)
      values
    end
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:node) { Chef::Node.new }
  let(:ohai) { Ohai::System.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::RegistryKey.new(resource_name, run_context) }

  let(:parent) { "Opscode" }
  let(:child) { "Whatever" }
  let(:key_parent) { "Software\\#{parent}" }
  let(:key_child) { "#{key_parent}\\#{child}" }
  let(:reg_parent) { "HKLM\\#{key_parent}" }
  let(:reg_child) { "HKLM\\#{key_child}" }
  let(:hive_class) { ::Win32::Registry::HKEY_LOCAL_MACHINE }
  let(:resource_name) { "This is the name of my Resource" }

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:registry) { Chef::Win32::Registry.new(run_context) }

  let(:node_name) { "windowsbox" }
  let(:run_id) { SecureRandom.uuid }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_status) { Chef::RunStatus.new(node, events) }
  let(:action_collection) { Chef::ActionCollection.new(events) }

  let(:rest_client) do
    rest_client = double("Chef::ServerAPI")

    # allow().to receive(:message).with(::any arguments::) syntax seems to be broken here
    allow(rest_client).to receive(:post).and_return("uri" => "https://example.com/reports/nodes/#{node_name}/runs/#{run_id}")
    allow(rest_client).to receive(:create_url).and_return("reports/nodes/#{node_name}/run/#{run_id}")
    allow(rest_client).to receive(:raw_http_request).and_return({ "result" => "ok" })

    rest_client
  end

  let(:resource_reporter) { Chef::ResourceReporter.new(rest_client) }

  def clean_registry
    if windows64?
      # clean 64-bit space on WOW64
      registry.architecture = :x86_64
      registry.delete_key(reg_parent, true)
      registry.architecture = :machine
    end
    # clean 32-bit space on WOW64
    registry.architecture = :i386
    registry.delete_key(reg_parent, true)
    registry.architecture = :machine
  end

  def reset_registry
    clean_registry
    hive_class.create(key_parent, Win32::Registry::KEY_WRITE | 0x0100)
    hive_class.create(key_parent, Win32::Registry::KEY_WRITE | 0x0200)
  end

  context "when running on non-Windows", :unix_only do
    let(:registry_key) { "HKCU\\Software\\Opscode" }
    let(:registry_key_values) { [{ name: "Color", type: :string, data: "Orange" }] }
    subject do
      new_resource.key(registry_key)
      new_resource.values(registry_key_values)
      new_resource.run_action(:create)
    end
    it "raise an exception because we don't have a windows registry on non-Windows" do
      expect { subject }.to raise_error(Chef::Exceptions::Win32NotWindows)
    end
  end

  context "when running on Windows", :windows_only do
    # this is moderately brittle, but it seems to be the order of operations
    # necessary to get a report out of the resource reporter
    before do
      events
      node
      node.name(node_name)
      ohai
      ohai.all_plugins
      node.consume_external_attrs(ohai.data, {})
      run_context
      action_collection
      new_resource
      registry

      reset_registry
    end

    after do
      clean_registry
    end
    subject do
      resource_reporter
      events.register(resource_reporter)
      events.register(action_collection)
      resource_reporter.action_collection_registration(action_collection)
      resource_reporter.run_started(run_status)
      new_resource.key(registry_key)
      new_resource.values(registry_key_values)
      new_resource.run_action(action)
    end

    context "action :create" do
      let(:action) { :create }
      let(:registry_key_values) { [{ name: "Color", type: :string, data: "Orange" }] }
      let(:registry_key) { reg_child }
      before { reset_registry }
      it "creates a registry key if the key is missing" do
        subject
        expect(registry.key_exists?(registry_key)).to be true
        expect(registry.get_values(registry_key)).to eq(registry_key_values)
        report = resource_reporter.prepare_run_data
        expect(report["resources"][0]["after"][:values]).to eq(registry_key_values)
      end

      it "does not create a registry key if it already exists" do
        registry.create_key(registry_key, true)
        registry_key_values.each do |rkv|
          registry.set_value(registry_key, rkv)
        end
        subject
        report = resource_reporter.prepare_run_data
        expect(report["total_res_count"]).to eq("0")
      end

      let(:prepopulated_values) do
        [
          { name: "TheBefore", type: :multi_string, data: %w{abc def} },
          { name: "ReportingVal1", type: :dword, data: 1234 },
        ]
      end

      def prepopulate(key, values)
        registry.create_key(key, true)

        values.each do |value|
          registry.set_value(registry_key, value)
        end
      end

      describe "new key" do
        before { new_resource.recursive(true) }
        let(:registry_key) { "#{reg_child}\\NewValues" }
        let(:registry_key_values) { [{ name: "SomeValue", type: :string, data: "Blue" }] }

        it "creates the new registry key with the specified values" do
          subject
          expect(registry.key_exists?(registry_key)).to be true
          expect(registry.value_exists?(registry_key, registry_key_values[-1])).to be true
        end
      end

      context "an existing key" do
        let(:registry_key) { "#{reg_child}\\ExistingValue" }
        let(:initial_values) { [{ name: "SomeValue", type: :dword, data: 3321 }] }

        before do
          prepopulate(registry_key, initial_values)
        end

        context "same value, type, and data" do
          let(:registry_key_values) { initial_values }

          it "doesn't update the key if the values are the same" do
            subject
            expect(new_resource).not_to be_updated_by_last_action
            expect(registry.key_exists?(registry_key)).to be true
            expect(registry.value_exists?(registry_key, initial_values[-1])).to be true
          end
        end

        context "same value, type, but datatype of data differs" do
          let(:registry_key_values) { [{ name: "SomeValue", type: :dword, data: "3321" }] }

          it "updates the key if the value type is different" do
            subject
            expect(new_resource).not_to be_updated_by_last_action
            expect(registry.key_exists?(registry_key)).to be true
            expect(registry.value_exists?(registry_key, initial_values[-1])).to be true
          end
        end

        context "same value, different type, data type differs" do
          let(:registry_key_values) { [{ name: "SomeValue", type: :multi_string, data: %w{3321 2231} }] }

          it "updates the key if the value type is different" do
            subject
            expect(new_resource).to be_updated_by_last_action
            expect(registry.key_exists?(registry_key)).to be true
            expect(registry.value_exists?(registry_key, registry_key_values[-1])).to be true
          end
        end

        context "parent exists, but not child" do
          let(:registry_key) { "#{reg_child}\\DoesNotExist" }
          before { new_resource.recursive(false) }
          it "creates the child if the parent exists" do
            subject
            expect(registry.key_exists?(registry_key)).to eq(true)
            expect(registry.value_exists?(registry_key, registry_key_values[-1])).to be true
          end
        end

        context "missing type key" do
          let(:registry_key) { "#{reg_child}\\MissingTypeKey" }
          let(:registry_key_values) { [{ name: "SomeValue", data: "3321" }] }
          it "raises RegKeyValuesTypeMissing" do
            expect { subject }.to raise_error(Chef::Exceptions::RegKeyValuesTypeMissing)
          end
        end

        context "missing data key" do
          let(:registry_key) { "#{reg_child}\\MissingDataKey" }
          let(:registry_key_values) { [{ name: "SomeValue", type: :string }] }
          it "raises RegKeyValuesTypeMissing" do
            expect { subject }.to raise_error(Chef::Exceptions::RegKeyValuesDataMissing)
          end
        end

        context "new value" do
          let(:registry_key_values) { [{ name: "NewValue", type: :string, data: "Green" }] }

          it "creates a value if it does not exist" do
            subject
            expect(new_resource).to be_updated_by_last_action
            expect(registry.key_exists?(registry_key)).to be true
            expect(registry.value_exists?(registry_key, registry_key_values[-1])).to be true
          end
        end
      end

      context "two deep" do
        let(:registry_key) { "#{reg_child}\\#{rand(1000..2000)}\\#{rand(1000..3000)}}" }
        context "recursive true" do
          before { new_resource.recursive(true) }
          it "creates the child" do
            subject
            expect(registry.key_exists?(registry_key)).to eq(true)
            expect(registry.value_exists?(registry_key, registry_key_values[-1])).to be true
          end
        end

        context "recursive false" do
          before { new_resource.recursive(false) }
          it "raises Win32RegNoRecursive" do
            expect { subject }.to raise_error(Chef::Exceptions::Win32RegNoRecursive)
          end
        end
      end

      context "create key with multiple values" do
        before { new_resource.recursive(true) }
        let(:registry_key) { "#{reg_child}\\MultipleValueKey" }
        let(:registry_key_values) do
          [
            { name: "SomeValue", type: :string, data: "Blue" },
            { name: "AnotherValue", type: :string, data: "Green" },
          ]
        end
        it "creates all the values" do
          subject
          expect(registry.key_exists?(registry_key)).to eq(true)
          registry_key_values.each do |value|
            expect(registry.value_exists?(registry_key, value)).to be true
          end
        end

        context "when only_record_changes is true" do
          before do
            new_resource.only_record_changes(true)
            prepopulate(registry_key, prepopulated_values)
          end
          let(:registry_key) { "#{reg_child}\\OnlyRecordChanges" }
          let(:registry_key_values) { [{ name: "ReportingVal1", type: :string, data: rand(1235..10000) }] }

          it "should only report the changed value" do
            subject
            report = resource_reporter.prepare_run_data

            expect(report["action"]).to eq("end")
            expect(report["resources"][0]["type"]).to eq(:registry_key)
            expect(report["resources"][0]["name"]).to eq(resource_name)
            expect(report["resources"][0]["id"]).to eq(registry_key)
            expect(report["resources"][0]["after"][:values]).to eq(registry_key_values)
            expect(report["resources"][0]["before"][:values]).to eq(prepopulated_values.select { |ppv| ppv[:name] == "ReportingVal1" })
            expect(report["resources"][0]["result"]).to eq("create")
            expect(report["status"]).to eq("success")
            expect(report["total_res_count"]).to eq("1")
          end
        end

        context "when only_record_changes is the default(false)" do
          before do
            prepopulate(registry_key, prepopulated_values)
          end
          let(:registry_key) { "#{reg_child}\\RecordItAll" }
          let(:registry_key_values) { [{ name: "ReportingVal1", type: :string, data: rand(1235..10000) }] }

          it "should only report the changed value" do
            subject
            report = resource_reporter.prepare_run_data

            expect(report["resources"][0]["after"][:values]).to eq(registry_key_values)
            expect(report["resources"][0]["before"][:values]).to eq(prepopulated_values)
            expect(report["status"]).to eq("success")
            expect(report["total_res_count"]).to eq("1")
          end

        end
      end
    end
  end
end
