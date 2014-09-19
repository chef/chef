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

describe Chef::Resource::Service::Aix, :requires_root, :aix_only do

  include Chef::Mixin::ShellOut

  def service_started?
    expect(shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(' ').last).to eq("active")
  end

  def service_stopped?
    expect(shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(' ').last).to eq("inoperative")
  end

  def get_service_pid
    args = shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(' ')
    if args.length == 3
      args[1]
    else
      args[2]
    end
  end

  # Actual tests
  let(:new_resource) do
    new_resource = Chef::Resource::Service.new("testchefsubsys", run_context)
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  before(:all) do
    script_dir = File.join(File.dirname(__FILE__), "/../assets/")
    shell_out!("mkssys -s testchefsubsys -p #{script_dir}/testchefsubsys -u 0 -S -n 15 -f 9 -R -Q")
  end

  after(:all) do
    shell_out!("rmssys -s testchefsubsys")
  end

  describe "start service" do
    it "should start the service" do
      new_resource.run_action(:start)
      service_started?
    end
  end

  describe "stop service" do
   it "should stop the service" do
      new_resource.run_action(:stop)
      service_stopped?
    end
  end

  describe "restart service" do
    it "should restart the service" do
      new_resource.run_action(:restart)
      service_started?
    end
  end

  describe "reload service" do
    before do
      new_resource.run_action(:start)
      @current_pid = get_service_pid
    end

    it "should reload the service" do
      new_resource.run_action(:reload)
      service_started?
      expect(get_service_pid).not_to eq(@current_pid)
    end
  end
end
