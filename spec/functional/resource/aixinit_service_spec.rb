# encoding: UTF-8
#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'functional/resource/base'
require 'chef/mixin/shell_out'
require 'fileutils'

describe Chef::Resource::Service::Aixinit, :requires_root, :unix_only do

  include Chef::Mixin::ShellOut

  # Platform specific validation routines.
  def service_should_be_started(file_name)
    # The existance of this file indicates that the service was started.
    expect(File.exists("/tmp/#{file_name}").to be_true
  end

  def service_should_be_stopped(file_name)
    expect(File.exists("/tmp/#{file_name}").to be_false
  end

  def search_symlinks(run_level = nil, status = nil, priority = nil)
    directory = []
    if priority.is_a?Hash
      priority.each do |level,o|
        search_directory << "/etc/rc.d/rc#{level}.d/#{(o[0] == :start ? 'S' : 'K')}#{o[1]}#{new_resource.service_name}"
      end
      directory
    else
      directory << "/etc/rc.d/rc#{run_level}.d/#{status}#{priority}#{new_resource.service_name}"]
    end
    File.delete(*directory)

  end

  def delete_test_files
    files = Dir.glob(Dir.glob("/tmp/chefinittest[a-z_]*.txt"))
    File.delete(*files)
  end

  # Actual tests
  let(:new_resource) do
    new_resource = Chef::Resource::Service.new("chefinittest", run_context)
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  before(:all) do
    File.delete("/etc/rc.d/init.d/chefinittest")
    FileUtils.cp("../assets/chefinittest", "/etc/rc.d/init.d/chefinittest")
  end

  after(:all) do
    File.delete("/etc/rc.d/init.d/chefinittest")
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
      service_started?("chef.txt")
    end
  end

  describe "stop service" do
    before do
      new_resource.run_action(:start)
    end

    it "should stop the service" do
      new_resource.run_action(:stop)
      service_stopped?("chef.txt")
    end
  end

  describe "restart service" do
    it "should restart the service" do
      new_resource.run_action(:restart)
      service_started?("chef_restart.txt")
    end
  end

  describe "reload service" do
    it "should reload the service" do
      new_resource.run_action(:reload)
      service_started?("chef_reload.txt")
    end
  end

  describe "enable service" do

    context "when the service doesn't set a priority" do
      after do
        delete_files(search_symlinks(2,'S'))
      end

      it "creates symlink with status S" do
        new_resource.run_action(:enable)
        expect(Dir.glob(search_symlinks(2,'S'))).to eq(["/etc/rc.d/rc2.d/Schef"])
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        new_resource.priority(75)
      end

      after do
        delete_files(search_symlinks(2,'S',75))
      end

      it "creates a symlink with status S and a priority" do
        new_resource.run_action(:enable)
        expect(Dir.glob(search_symlinks(2,'S',75))).to eq(["/etc/rc.d/rc2.d/S75chef"])
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        priority = {2 => [:start, 20], 3 => [:stop, 10]}
        new_resource.priority(priority)
      end

      after do
        delete_files(search_symlinks(2,'S',new_resource.priority))
      end

      it "create symlink with status start (S) or stop (K) and a priority " do
        new_resource.run_action(:enable)
        expect(Dir.glob(search_symlinks(2,'S',new_resource.priority))).to eq(["/etc/rc.d/rc2.d/S20chef", "/etc/rc.d/rc3.d/K10chef"])
      end
    end
  end

  describe "disable_service" do
    context "when the service doesn't set a priority" do
      after do
        delete_files(search_symlinks(2,'S'))
      end

      it "creates symlink with status S" do
        new_resource.run_action(:disable)
        expect(Dir.glob(search_symlinks(2,'K'))).to eq(["/etc/rc.d/rc2.d/Kchef"])
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        @new_resource.priority(75)
      end

      after do
        delete_files(search_symlinks(2,'K',25))
      end

      it "creates a symlink with status K and a priority" do
        new_resource.run_action(:enable)
        expect(Dir.glob(search_symlinks(2,'K',25))).to eq(["/etc/rc.d/rc2.d/K25chef"])
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        @priority = {2 => [:stop, 20], 3 => [:start, 10]}
        @new_resource.priority(@priority)
      end

      after do
        delete_files(search_symlinks(2,'k',80))
      end

      it "create symlink with status stop (K) and a priority " do
        new_resource.run_action(:enable)
        expect(Dir.glob(search_symlinks(2,'K',80))).to eq(["/etc/rc.d/rc2.d/K80chef"])
      end
    end
  end
end
