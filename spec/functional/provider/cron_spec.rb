require 'spec_helper'
require 'ohai'

describe "Chef Provider for Cron" do
  # Order the tests for proper cleanup and execution
  RSpec.configure do |config|
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description }
    end
  end

  # Load ohai only once
  ohai = Ohai::System.new
  ohai.all_plugins

  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Cron.new("Chef functional test cron", @run_context)
    @new_resource.user "u0011729"
    @new_resource.minute "30"
    @new_resource.command "/bin/true"
    
    providerClass = Chef::Platform.find_provider(ohai[:platform], ohai[:version], @new_resource)
    @provider = providerClass.new(@new_resource, @run_context)
  end

  describe "testcase 1: create action" do
    it "should create a crontab entry" do
      @provider.load_current_resource
      @provider.cron_exists.should be_false
      @provider.run_action(:create)
      # Verify if the cron is created successfully
      @provider.load_current_resource
      @provider.cron_exists.should be_true
    end
  end

  describe "testcase 2: delete action" do
    it "should delete a crontab entry" do
      # Note that test cron is by previous test
      @provider.load_current_resource
      @provider.run_action(:delete)
      # Verify if the cron is deleted successfully
      @provider.load_current_resource
      @provider.cron_exists.should be_false
    end
  end
end
