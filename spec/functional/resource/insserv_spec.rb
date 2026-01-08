#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef/mixin/shell_out"
require "fileutils"

describe Chef::Resource::Service, :requires_root, :opensuse do

  include Chef::Mixin::ShellOut

  def service_should_be_enabled
    expect(shell_out!("/sbin/insserv -r -f #{new_resource.service_name}").exitstatus).to eq(0)
    expect(shell_out!("/sbin/insserv -d -f #{new_resource.service_name}").exitstatus).to eq(0)
    !Dir.glob("/etc/rc*/**/S*#{service_name}").empty?
  end

  def service_should_be_disabled
    expect(shell_out!("/sbin/insserv -r -f #{new_resource.service_name}").exitstatus).to eq(0)
    Dir.glob("/etc/rc*/**/S*#{service_name}").empty?
  end

  # Platform specific validation routines.
  def service_should_be_started(file_name)
    # The existence of this file indicates that the service was started.
    expect(File.exist?("#{Dir.tmpdir}/#{file_name}")).to be_truthy
  end

  def service_should_be_stopped(file_name)
    expect(File.exist?("#{Dir.tmpdir}/#{file_name}")).to be_falsey
  end

  def delete_test_files
    files = Dir.glob("#{Dir.tmpdir}/init[a-z_]*.txt")
    File.delete(*files)
  end

  # Actual tests
  let(:new_resource) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)

    new_resource = Chef::Resource::Service.new("inittest", run_context)
    new_resource.provider Chef::Provider::Service::Insserv
    new_resource.supports({ status: true, restart: true, reload: true })
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  let(:service_name) { "Chef::Util::PathHelper.escape_glob_dir(current_resource.service_name)" }

  let(:current_resource) do
    provider.load_current_resource
    provider.current_resource
  end

  before(:all) do
    File.delete("/etc/init.d/inittest") if File.exist?("/etc/init.d/inittest")
    FileUtils.cp((File.join(__dir__, "/../assets/inittest")).to_s, "/etc/init.d/inittest")
    FileUtils.chmod(0755, "/etc/init.d/inittest")
  end

  after(:all) do
    File.delete("/etc/init.d/inittest") if File.exist?("/etc/init.d/inittest")
  end

  before(:each) do
    delete_test_files
  end

  after(:each) do
    delete_test_files
  end

  describe "start service" do
    it "should start the service" do
      new_resource.run_action(:start)
      service_should_be_started("inittest.txt")
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      new_resource.run_action(:start)
      service_should_be_started("inittest.txt")
      expect(new_resource).to be_updated_by_last_action
      new_resource.run_action(:start)
      service_should_be_started("inittest.txt")
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "stop service" do
    before do
      new_resource.run_action(:start)
    end

    it "should stop the service" do
      new_resource.run_action(:stop)
      service_should_be_stopped("inittest.txt")
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      new_resource.run_action(:stop)
      service_should_be_stopped("inittest.txt")
      expect(new_resource).to be_updated_by_last_action
      new_resource.run_action(:stop)
      service_should_be_stopped("inittest.txt")
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "restart service" do
    before do
      new_resource.run_action(:start)
    end

    it "should restart the service" do
      new_resource.run_action(:restart)
      service_should_be_started("inittest_restart.txt")
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      skip "FIXME: restart is not idempotent"
      new_resource.run_action(:restart)
      service_should_be_disabled
      expect(new_resource).to be_updated_by_last_action
      new_resource.run_action(:restart)
      service_should_be_disabled
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "reload service" do
    before do
      new_resource.run_action(:start)
    end

    it "should reload the service" do
      new_resource.run_action(:reload)
      service_should_be_started("inittest_reload.txt")
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      skip "FIXME: reload is not idempotent"
      new_resource.run_action(:reload)
      service_should_be_disabled
      expect(new_resource).to be_updated_by_last_action
      new_resource.run_action(:reload)
      service_should_be_disabled
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "enable service" do
    it "should enable the service" do
      new_resource.run_action(:enable)
      service_should_be_enabled
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      new_resource.run_action(:enable)
      service_should_be_enabled
      new_resource.run_action(:enable)
      service_should_be_enabled
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "disable_service" do
    it "should disable the service" do
      new_resource.run_action(:disable)
      service_should_be_disabled
      expect(new_resource).to be_updated_by_last_action
    end

    it "should be idempotent" do
      new_resource.run_action(:disable)
      service_should_be_disabled
      new_resource.run_action(:disable)
      service_should_be_disabled
      expect(new_resource).not_to be_updated_by_last_action
    end
  end
end
