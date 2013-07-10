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
    @new_resource.user  ohai[:current_user]
    @new_resource.minute "30"
    @new_resource.command "/bin/true"
    
    @providerClass = Chef::Platform.find_provider(ohai[:platform], ohai[:version], @new_resource)
    @provider = @providerClass.new(@new_resource, @run_context)
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

  describe "testcase 3: create action with various attributes" do
    def create_and_validate
      @provider.load_current_resource
      @provider.cron_exists.should be_false
      if @providerClass == Chef::Provider::Cron::Aix
         expect {@provider.run_action(:create)}.to raise_error(Chef::Exceptions::Cron, "Aix cron entry does not support environment variables. Please set them in script and use script in cron.")
      else
        @provider.run_action(:create)
        # Verify if the cron is created successfully
        @provider.load_current_resource
        @provider.cron_exists.should be_true
      end
    end

    def validate_cron_attribute(attribute, expected_value)
      return if @providerClass == Chef::Provider::Cron::Aix
      # Test if the attribute exists as attribute or on command
      current_resource = @provider.current_resource
      new_val = current_resource.send(attribute.to_sym)
      if new_val
        expect(new_val).to eql(expected_value)
      else
        # command should have attribute value set
        expect(current_resource.command).to include(attribute.upcase)
        expect(current_resource.command).to include(expected_value)
      end
    end

    after do
      @provider.load_current_resource
      @provider.run_action(:delete)
      # Verify if the cron is deleted successfully
      @provider.load_current_resource
      @provider.cron_exists.should be_false
    end

    it "should create a crontab entry for mailto attribute" do
      @new_resource.mailto "cheftest@example.com"
      create_and_validate
      validate_cron_attribute("mailto", "cheftest@example.com")
    end

    it "should create a crontab entry for path attribute" do
      @new_resource.path "/usr/local/bin"
      create_and_validate
      validate_cron_attribute("path", "/usr/local/bin")
    end

    it "should create a crontab entry for shell attribute" do
      @new_resource.shell "/bin/bash"
      create_and_validate
      validate_cron_attribute("shell", "/bin/bash")
    end

    it "should create a crontab entry for home attribute" do
      @new_resource.home "/home/opscode"
      create_and_validate
      validate_cron_attribute("home", "/home/opscode")
    end
  end

  describe "testcase 4: negative tests for create action" do
    def create_and_validate
      @provider.load_current_resource
      @provider.cron_exists.should be_false
      expect { @provider.run_action(:create) }.to raise_error(Chef::Exceptions::Cron, /Error updating state of #{@new_resource.name}, exit: 1/)
    end

    it "should not create cron with invalid minute" do
      @new_resource.minute "invalid"
      create_and_validate
    end

    it "should not create cron with invalid user" do
      @new_resource.user "1-really-really-invalid-user-name"
      create_and_validate
    end

  end
end
