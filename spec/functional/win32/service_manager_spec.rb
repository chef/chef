#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'spec_helper'
if Chef::Platform.windows?
  require 'chef/application/windows_service_manager'
end

#
# ATTENTION:
# This test creates a windows service for testing purposes and runs it
# as Local System on windows boxes.
# This test will fail if you run the tests inside a Windows VM by
# sharing the code from your host since Local System account by
# default can't see the mounted partitions.
# Run this test by copying the code to a local VM directory or setup
# Local System account to see the maunted partitions for the shared
# directories.
#

describe "Chef::Application::WindowsServiceManager", :windows_only, :system_windows_service_gem_only do

  # Some helper methods.

  def test_service_exists?
    ::Win32::Service.exists?("spec-service")
  end

  def test_service_state
    ::Win32::Service.status("spec-service").current_state
  end

  def service_manager
    Chef::Application::WindowsServiceManager.new(test_service)
  end

  def cleanup
    # Uninstall if the test service is installed.
    if test_service_exists?

      # We can only uninstall when the service is stopped.
      if test_service_state != "stopped"
        ::Win32::Service.send("stop", "spec-service")
        while test_service_state != "stopped"
          sleep 1
        end
      end

      ::Win32::Service.delete("spec-service")
    end

    # Delete the test_service_file if it exists
    if File.exists?(test_service_file)
      File.delete(test_service_file)
    end

  end


  # Definition for the test-service

  let(:test_service) {
    {
      :service_name => "spec-service",
      :service_display_name => "Spec Test Service",
      :service_description => "Service for testing Chef::Application::WindowsServiceManager.",
      :service_file_path => File.expand_path(File.join(File.dirname(__FILE__), '../../support/platforms/win32/spec_service.rb'))
    }
  }

  # Test service creates a file for us to verify that it is running.
  # Since our test service is running as Local System we should look
  # for the file it creates under SYSTEM temp directory

  let(:test_service_file) {
    "#{ENV['SystemDrive']}\\windows\\temp\\spec_service_file"
  }

  context "with invalid service definition" do
    it "throws an error when initialized with no service definition" do
      lambda { Chef::Application::WindowsServiceManager.new(nil) }.should raise_error(ArgumentError)
    end

    it "throws an error with required missing options" do
      test_service.each do |key,value|
        service_def = test_service.dup
        service_def.delete(key)

        lambda { Chef::Application::WindowsServiceManager.new(service_def) }.should raise_error(ArgumentError)
      end
    end
  end

  context "with valid definition" do
    before(:each) do
      @service_manager_output = [ ]
      # Uncomment below lines to debug this test
      # original_puts = $stdout.method(:puts)
      $stdout.stub(:puts) do |message|
        @service_manager_output << message
        # original_puts.call(message)
      end
    end

    after(:each) do
      cleanup
    end

    context "when service doesn't exist" do
      it "default => should say service don't exist" do
        service_manager.run

        @service_manager_output.grep(/doesn't exist on the system/).length.should > 0
      end

      it "install => should install the service" do
        service_manager.run(["-a", "install"])

        test_service_exists?.should be_true
      end

      it "other actions => should say service doesn't exist" do
        ["delete", "start", "stop", "pause", "resume", "uninstall"].each do |action|
          service_manager.run(["-a", action])
          @service_manager_output.grep(/doesn't exist on the system/).length.should > 0
          @service_manager_output = [ ]
        end
      end
    end

    context "when service exists" do
      before(:each) do
        service_manager.run(["-a", "install"])
      end

      it "install => should say service already exists" do
          service_manager.run(["-a", "install"])
          @service_manager_output.grep(/already exists/).length.should > 0
      end

      context "and service is stopped" do
        ["delete", "uninstall"].each do |action|
          it "#{action} => should remove the service", :volatile do
            service_manager.run(["-a", action])
            test_service_exists?.should be_false
          end
        end

        it "default, status => should say service is stopped" do
          service_manager.run([ ])
          @service_manager_output.grep(/stopped/).length.should > 0
          @service_manager_output = [ ]

          service_manager.run(["-a", "status"])
          @service_manager_output.grep(/stopped/).length.should > 0
        end

        it "start should start the service", :volatile do
          service_manager.run(["-a", "start"])
          test_service_state.should == "running"
          File.exists?(test_service_file).should be_true
        end

        it "stop should not affect the service" do
          service_manager.run(["-a", "stop"])
          test_service_state.should == "stopped"
        end


        ["pause", "resume"].each do |action|
          it "#{action} => should raise error" do
            lambda {service_manager.run(["-a", action])}.should raise_error(::Win32::Service::Error)
          end
        end

        context "and service is started", :volatile do
          before(:each) do
            service_manager.run(["-a", "start"])
          end

          ["delete", "uninstall"].each do |action|
            it "#{action} => should remove the service", :volatile do
              service_manager.run(["-a", action])
              test_service_exists?.should be_false
            end
          end

          it "default, status => should say service is running" do
            service_manager.run([ ])
            @service_manager_output.grep(/running/).length.should > 0
            @service_manager_output = [ ]

            service_manager.run(["-a", "status"])
            @service_manager_output.grep(/running/).length.should > 0
          end

          it "stop should stop the service" do
            service_manager.run(["-a", "stop"])
            test_service_state.should == "stopped"
          end

          it "pause should pause the service" do
            service_manager.run(["-a", "pause"])
            test_service_state.should == "paused"
          end

          it "resume should have no affect" do
            service_manager.run(["-a", "resume"])
            test_service_state.should == "running"
          end
        end

        context "and service is paused", :volatile do
          before(:each) do
            service_manager.run(["-a", "start"])
            service_manager.run(["-a", "pause"])
          end

          actions = ["delete", "uninstall"]
          actions.each do |action|
            it "#{action} => should remove the service" do
              service_manager.run(["-a", action])
              test_service_exists?.should be_false
            end
          end

          it "default, status => should say service is paused" do
            service_manager.run([ ])
            @service_manager_output.grep(/paused/).length.should > 0
            @service_manager_output = [ ]

            service_manager.run(["-a", "status"])
            @service_manager_output.grep(/paused/).length.should > 0
          end

          it "stop should stop the service" do
            service_manager.run(["-a", "stop"])
            test_service_state.should == "stopped"
          end

          it "pause should not affect the service" do
            service_manager.run(["-a", "pause"])
            test_service_state.should == "paused"
          end

          it "start should raise an error" do
            lambda {service_manager.run(["-a", "start"])}.should raise_error(::Win32::Service::Error)
          end

        end
      end
    end
  end
end
