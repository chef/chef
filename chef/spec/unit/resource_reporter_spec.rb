#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Prajakta Purohit (prajakta@opscode.com>)
#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path("../../spec_helper", __FILE__)
require 'chef/resource_reporter'

describe Chef::ResourceReporter do

  before do
    @resource_reporter = Chef::ResourceReporter.new
    @new_resource      = Chef::Resource::File.new("/tmp/a-file.txt")
    @current_resource  = Chef::Resource::File.new("/tmp/a-file.txt")
  end

  context "when first created" do

    it "has no updated resources" do
      @resource_reporter.should have(0).updated_resources
    end

  end

  context "when a resource fails before loading current state" do
    before do
      @exception = Exception.new
      @resource_reporter.resource_failed(@new_resource, :create, @exception)
    end

    it "collects the resource as an updated resource" do
      @resource_reporter.should have(1).updated_resources
    end

    it "collects the desired state of the resource" do
      update_record = @resource_reporter.updated_resources.first
      update_record[:new_resource].should == @new_resource
    end

  end

  context "once the a resource's current state is loaded" do
    before do
      @resource_reporter.resource_current_state_loaded(@new_resource, :create, @current_resource)
    end

    context "and the resource was not updated" do
      before do
        @resource_reporter.resource_up_to_date(@new_resource, :create)
      end

      it "has no updated resources" do
        @resource_reporter.should have(0).updated_resources
      end
    end

    context "and the resource was updated" do
      before do
        @new_resource.content("this is the old content")
        @current_resource.content("this is the new hotness")
        @resource_reporter.resource_updated(@new_resource, :create)
      end

      it "collects the updated resource" do
        @resource_reporter.should have(1).updated_resources
      end

      it "collects the old state of the resource" do
        update_record = @resource_reporter.updated_resources.first

        update_record[:current_resource].should == @current_resource
      end

      it "collects the new state of the resource" do
        update_record = @resource_reporter.updated_resources.first

        update_record[:new_resource].should == @new_resource
      end

      context "and a subsequent resource fails before loading current resource" do
        before do
          @next_new_resource = Chef::Resource::Service.new("apache2")
          @exception = Exception.new
          @resource_reporter.resource_failed(@next_new_resource, :create, @exception)
        end

        it "collects the desired state of the failed resource" do
          failed_resource_update = @resource_reporter.updated_resources.last
          failed_resource_update[:new_resource].should == @next_new_resource
        end

        it "does not have the current state of the failed resource" do
          failed_resource_update = @resource_reporter.updated_resources.last
          failed_resource_update[:current_resouce].should be_nil
        end
      end
    end

    context "and the resource failed to converge" do
      before do
        @exception = Exception.new
        @resource_reporter.resource_failed(@new_resource, :create, @exception)
      end

      it "collects the resource as an updated resource" do
        @resource_reporter.should have(1).updated_resources
      end

      it "collects the desired state of the resource" do
        update_record = @resource_reporter.updated_resources.first
        update_record[:new_resource].should == @new_resource
      end

      it "collects the current state of the resource" do
        update_record = @resource_reporter.updated_resources.first
        update_record[:current_resource].should == @current_resource
      end
    end

  end


end
