# encoding: UTF-8
#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "functional/resource/base"
require "chef/mixin/shell_out"

shared_examples "src service" do

  include Chef::Mixin::ShellOut

  def service_should_be_started
    expect(shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(" ").last).to eq("active")
  end

  def service_should_be_stopped
    expect(shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(" ").last).to eq("inoperative")
  end

  def get_service_pid
    args = shell_out!("lssrc -a | grep #{new_resource.service_name}").stdout.split(" ")
    if args.length == 3
      args[1]
    else
      args[2]
    end
  end

  describe "start service" do
    it "should start the service" do
      new_resource.run_action(:start)
      service_should_be_started
    end
  end

  describe "stop service" do
    before do
      new_resource.run_action(:start)
    end

    it "should stop the service" do
      new_resource.run_action(:stop)
      service_should_be_stopped
    end
  end

  describe "restart service" do
    before do
      new_resource.run_action(:start)
    end

    it "should restart the service" do
      new_resource.run_action(:restart)
      service_should_be_started
    end
  end
end

describe Chef::Resource::Service, :requires_root, :aix_only do

  include Chef::Mixin::ShellOut

  def get_user_id
    shell_out("id -u #{ENV['USER']}").stdout.chomp
  end

  describe "When service is a subsystem" do
    before(:all) do
      script_dir = File.join(File.dirname(__FILE__), "/../assets/")
      shell_out!("mkssys -s ctestsys -p #{script_dir}/testchefsubsys -u #{get_user_id} -S -n 15 -f 9 -R -Q")
    end

    after(:each) do
      shell_out("stopsrc -s ctestsys")
    end

    after(:all) do
      shell_out!("rmssys -s ctestsys")
    end

    let(:new_resource) do
      new_resource = Chef::Resource::Service.new("ctestsys", run_context)
      new_resource
    end

    let(:provider) do
      provider = new_resource.provider_for_action(new_resource.action)
      provider
    end

    it_behaves_like "src service"
  end

  # Cannot run this test on a WPAR
  describe "When service is a group", :not_wpar do
    before(:all) do
      script_dir = File.join(File.dirname(__FILE__), "/../assets/")
      shell_out!("mkssys -s ctestsys -p #{script_dir}/testchefsubsys -u #{get_user_id} -S -n 15 -f 9 -R -Q -G ctestgrp")
    end

    after(:each) do
      shell_out("stopsrc -g ctestgrp")
    end

    after(:all) do
      # rmssys supports only -s option.
      shell_out!("rmssys -s ctestsys")
    end

    let(:new_resource) do
      new_resource = Chef::Resource::Service.new("ctestgrp", run_context)
      new_resource
    end

    let(:provider) do
      provider = new_resource.provider_for_action(new_resource.action)
      provider
    end

    it_behaves_like "src service"
  end
end
