require "spec_helper"
require "chef/recipe"

# The goal of these tests is to make sure that loading resources from a file creates the necessary notifications.
# Then once converge has started, both immediate and delayed notifications are called as the resources are converged.
# We want to do this WITHOUT actually converging any resources - we don't want to take time changing the system,
# we just want to make sure the run_context, the notification DSL and the converge hooks are working together
# to perform notifications.

# This test is extremely fragile since it mocks MANY different systems at once - any of them changes, this test
# breaks
describe "Notifications" do

  # We always pretend we are on OSx because that has a specific provider (HomebrewProvider) so it
  # tests the translation from Provider => HomebrewProvider
  let(:node) do
    n = Chef::Node.new
    n.override[:os] = "darwin"
    n
  end
  let(:cookbook_collection) { double("Chef::CookbookCollection").as_null_object }
  let(:events) { double("Chef::EventDispatch::Dispatcher").as_null_object }
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }
  let(:recipe) { Chef::Recipe.new("notif", "test", run_context) }
  let(:runner) { Chef::Runner.new(run_context) }

  before do
    # By default, every provider will do nothing
    p = Chef::Provider.new(nil, run_context)
    allow_any_instance_of(Chef::Resource).to receive(:provider_for_action).and_return(p)
    allow(p).to receive(:run_action)
  end

  it "should subscribe from one resource to another" do
    log_resource = recipe.declare_resource(:log, "subscribed-log") do
      message "This is a log message"
      action :nothing
      subscribes :write, "package[vim]", :immediately
    end

    package_resource = recipe.declare_resource(:package, "vim") do
      action :install
    end

    expect(log_resource).to receive(:run_action).with(:nothing, nil, nil).and_call_original

    expect(package_resource).to receive(:run_action).with(:install, nil, nil).and_call_original
    update_action(package_resource)

    expect(log_resource).to receive(:run_action).with(:write, :immediate, package_resource).and_call_original

    runner.converge
  end

  it "should notify from one resource to another immediately" do
    log_resource = recipe.declare_resource(:log, "log") do
      message "This is a log message"
      action :write
      notifies :install, "package[vim]", :immediately
    end

    package_resource = recipe.declare_resource(:package, "vim") do
      action :nothing
    end

    expect(log_resource).to receive(:run_action).with(:write, nil, nil).and_call_original
    update_action(log_resource)

    expect(package_resource).to receive(:run_action).with(:install, :immediate, log_resource).ordered.and_call_original

    expect(package_resource).to receive(:run_action).with(:nothing, nil, nil).ordered.and_call_original

    runner.converge
  end

  it "should notify from one resource to another before" do
    log_resource = recipe.declare_resource(:log, "log") do
      message "This is a log message"
      action :write
      notifies :install, "package[vim]", :before
    end
    update_action(log_resource, 2)

    package_resource = recipe.declare_resource(:package, "vim") do
      action :nothing
    end

    actions = []
    [ log_resource, package_resource ].each do |resource|
      allow(resource).to receive(:run_action).and_wrap_original do |m, action, notification_type, notifying_resource|
        actions << { resource: resource.to_s, action: action }
        actions[-1][:why_run] = Chef::Config[:why_run] if Chef::Config[:why_run]
        actions[-1][:notification_type] = notification_type if notification_type
        actions[-1][:notifying_resource] = notifying_resource.to_s if notifying_resource
        m.call(action, notification_type, notifying_resource)
      end
    end

    runner.converge

    expect(actions).to eq [
      # First it runs why-run to check if the resource would update
      { resource: log_resource.to_s,     action: :write,   why_run: true },
      # Then it runs the before action
      { resource: package_resource.to_s, action: :install, notification_type: :before, notifying_resource: log_resource.to_s },
      # Then it runs the actual action
      { resource: log_resource.to_s,     action: :write },
      { resource: package_resource.to_s, action: :nothing },
    ]
  end

  it "should not notify from one resource to another before if the resource is not updated" do
    log_resource = recipe.declare_resource(:log, "log") do
      message "This is a log message"
      action :write
      notifies :install, "package[vim]", :before
    end

    package_resource = recipe.declare_resource(:package, "vim") do
      action :nothing
    end

    actions = []
    [ log_resource, package_resource ].each do |resource|
      allow(resource).to receive(:run_action).and_wrap_original do |m, action, notification_type, notifying_resource|
        actions << { resource: resource.to_s, action: action }
        actions[-1][:why_run] = Chef::Config[:why_run] if Chef::Config[:why_run]
        actions[-1][:notification_type] = notification_type if notification_type
        actions[-1][:notifying_resource] = notifying_resource.to_s if notifying_resource
        m.call(action, notification_type, notifying_resource)
      end
    end

    runner.converge

    expect(actions).to eq [
      # First it runs why-run to check if the resource would update
      { resource: log_resource.to_s,     action: :write, why_run: true },
      # Then it does NOT run the before action
      # Then it runs the actual action
      { resource: log_resource.to_s,     action: :write },
      { resource: package_resource.to_s, action: :nothing },
    ]
  end

  it "should notify from one resource to another delayed" do
    log_resource = recipe.declare_resource(:log, "log") do
      message "This is a log message"
      action :write
      notifies :install, "package[vim]", :delayed
    end

    package_resource = recipe.declare_resource(:package, "vim") do
      action :nothing
    end

    expect(log_resource).to receive(:run_action).with(:write, nil, nil).and_call_original
    update_action(log_resource)

    expect(package_resource).to receive(:run_action).with(:nothing, nil, nil).ordered.and_call_original

    expect(package_resource).to receive(:run_action).with(:install, :delayed, nil).ordered.and_call_original

    runner.converge
  end

  describe "when one resource is defined lazily" do

    it "subscribes to a resource defined in a ruby block" do
      r = recipe
      t = self
      ruby_block = recipe.declare_resource(:ruby_block, "rblock") do
        block do
          log_resource = r.declare_resource(:log, "log") do
            message "This is a log message"
            action :write
          end
          t.expect(log_resource).to t.receive(:run_action).with(:write, nil, nil).and_call_original
          t.update_action(log_resource)
        end
      end

      package_resource = recipe.declare_resource(:package, "vim") do
        action :nothing
        subscribes :install, "log[log]", :delayed
      end

      # RubyBlock needs to be able to run for our lazy examples to work - and it alone cannot affect the system
      expect(ruby_block).to receive(:provider_for_action).and_call_original

      expect(package_resource).to receive(:run_action).with(:nothing, nil, nil).ordered.and_call_original

      expect(package_resource).to receive(:run_action).with(:install, :delayed, nil).ordered.and_call_original

      runner.converge
    end

    it "notifies from inside a ruby_block to a resource defined outside" do
      r = recipe
      t = self
      ruby_block = recipe.declare_resource(:ruby_block, "rblock") do
        block do
          log_resource = r.declare_resource(:log, "log") do
            message "This is a log message"
            action :write
            notifies :install, "package[vim]", :immediately
          end
          t.expect(log_resource).to t.receive(:run_action).with(:write, nil, nil).and_call_original
          t.update_action(log_resource)
        end
      end

      package_resource = recipe.declare_resource(:package, "vim") do
        action :nothing
      end

      # RubyBlock needs to be able to run for our lazy examples to work - and it alone cannot affect the system
      expect(ruby_block).to receive(:provider_for_action).and_call_original

      expect(package_resource).to receive(:run_action).with(:install, :immediate, instance_of(Chef::Resource::Log)).ordered.and_call_original

      expect(package_resource).to receive(:run_action).with(:nothing, nil, nil).ordered.and_call_original

      runner.converge
    end

  end

  # Mocks having the provider run successfully and update the resource
  def update_action(resource, times = 1)
    p = Chef::Provider.new(resource, run_context)
    expect(resource).to receive(:provider_for_action).exactly(times).times.and_return(p)
    expect(p).to receive(:run_action).exactly(times).times {
      resource.updated_by_last_action(true)
    }
  end

end
