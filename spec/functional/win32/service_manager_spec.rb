#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
if Chef::Platform.windows?
  require "chef/application/windows_service_manager"
end

#
# ATTENTION:
# This test creates a windows service for testing purposes and runs it
# as Local System (or an otherwise specified user) on windows boxes.
# This test will fail if you run the tests inside a Windows VM by
# sharing the code from your host since Local System account by
# default can't see the mounted partitions.
# Run this test by copying the code to a local VM directory or setup
# Local System account to see the maunted partitions for the shared
# directories.
#

describe "Chef::Application::WindowsServiceManager", :windows_only, :system_windows_service_gem_only, :appveyor_only do

  include_context "using Win32::Service"

  context "with invalid service definition" do
    it "throws an error when initialized with no service definition" do
      expect { Chef::Application::WindowsServiceManager.new(nil) }.to raise_error(ArgumentError)
    end

    it "throws an error with required missing options" do
      [:service_name, :service_display_name, :service_description, :service_file_path].each do |key|
        service_def = test_service.dup
        service_def.delete(key)

        expect { Chef::Application::WindowsServiceManager.new(service_def) }.to raise_error(ArgumentError)
      end
    end
  end

  context "with valid definition" do
    before(:each) do
      @service_manager_output = [ ]
      # Uncomment below lines to debug this test
      # original_puts = $stdout.method(:puts)
      allow($stdout).to receive(:puts) do |message|
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

        expect(@service_manager_output.grep(/doesn't exist on the system/).length).to be > 0
      end

      it "install => should install the service" do
        service_manager.run(["-a", "install"])

        expect(test_service_exists?).to be_truthy
      end

      it "other actions => should say service doesn't exist" do
        %w{delete start stop pause resume uninstall}.each do |action|
          service_manager.run(["-a", action])
          expect(@service_manager_output.grep(/doesn't exist on the system/).length).to be > 0
          @service_manager_output = [ ]
        end
      end
    end

    context "when service exists" do
      before(:each) do
        service_manager.run(["-a", "install"])
      end

      it "should have an own-process, non-interactive type" do
        status = ::Win32::Service.status("spec-service")
        expect(status[:service_type]).to eq("own process")
        expect(status[:interactive]).to be_falsey
      end

      it "install => should say service already exists" do
        service_manager.run(["-a", "install"])
        expect(@service_manager_output.grep(/already exists/).length).to be > 0
      end

      context "and service is stopped" do
        %w{delete uninstall}.each do |action|
          it "#{action} => should remove the service", :volatile do
            service_manager.run(["-a", action])
            expect(test_service_exists?).to be_falsey
          end
        end

        it "default, status => should say service is stopped" do
          service_manager.run([ ])
          expect(@service_manager_output.grep(/stopped/).length).to be > 0
          @service_manager_output = [ ]

          service_manager.run(["-a", "status"])
          expect(@service_manager_output.grep(/stopped/).length).to be > 0
        end

        it "start should start the service", :volatile do
          service_manager.run(["-a", "start"])
          expect(test_service_state).to eq("running")
          expect(File.exists?(test_service_file)).to be_truthy
        end

        it "stop should not affect the service" do
          service_manager.run(["-a", "stop"])
          expect(test_service_state).to eq("stopped")
        end

        %w{pause resume}.each do |action|
          it "#{action} => should raise error" do
            expect { service_manager.run(["-a", action]) }.to raise_error(SystemCallError)
          end
        end

        context "and service is started", :volatile do
          before(:each) do
            service_manager.run(["-a", "start"])
          end

          %w{delete uninstall}.each do |action|
            it "#{action} => should remove the service", :volatile do
              service_manager.run(["-a", action])
              expect(test_service_exists?).to be_falsey
            end
          end

          it "default, status => should say service is running" do
            service_manager.run([ ])
            expect(@service_manager_output.grep(/running/).length).to be > 0
            @service_manager_output = [ ]

            service_manager.run(["-a", "status"])
            expect(@service_manager_output.grep(/running/).length).to be > 0
          end

          it "stop should stop the service" do
            service_manager.run(["-a", "stop"])
            expect(test_service_state).to eq("stopped")
          end

          it "pause should pause the service" do
            service_manager.run(["-a", "pause"])
            expect(test_service_state).to eq("paused")
          end

          it "resume should have no affect" do
            service_manager.run(["-a", "resume"])
            expect(test_service_state).to eq("running")
          end
        end

        context "and service is paused", :volatile do
          before(:each) do
            service_manager.run(["-a", "start"])
            service_manager.run(["-a", "pause"])
          end

          actions = %w{delete uninstall}
          actions.each do |action|
            it "#{action} => should remove the service" do
              service_manager.run(["-a", action])
              expect(test_service_exists?).to be_falsey
            end
          end

          it "default, status => should say service is paused" do
            service_manager.run([ ])
            expect(@service_manager_output.grep(/paused/).length).to be > 0
            @service_manager_output = [ ]

            service_manager.run(["-a", "status"])
            expect(@service_manager_output.grep(/paused/).length).to be > 0
          end

          it "stop should stop the service" do
            service_manager.run(["-a", "stop"])
            expect(test_service_state).to eq("stopped")
          end

          it "pause should not affect the service" do
            service_manager.run(["-a", "pause"])
            expect(test_service_state).to eq("paused")
          end

          it "start should raise an error" do
            expect { service_manager.run(["-a", "start"]) }.to raise_error(::Win32::Service::Error)
          end

        end
      end
    end
  end
end
