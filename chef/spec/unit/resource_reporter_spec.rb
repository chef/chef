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

    it "reports a successful run" do
      @resource_reporter.status.should == "success"
    end

  end

  context "after the chef run completes" do
    before do
      @resource_reporter.run_completed
    end

    it "reports a successful run" do
      @resource_reporter.status.should == "success"
    end
  end

  context "when chef fails before converging any resources" do
    before do
      @exception = Exception.new
      @resource_reporter.run_failed(@exception)
    end

    it "sets the run status to 'failed'" do
      @resource_reporter.status.should == "failed"
    end

    it "keeps the exception data" do
      @resource_reporter.exception.should == @exception
    end

    # TODO: more design
    # The idea here is to reuse the error inspectors to capture "pretty"
    # descriptions of errors instead of just the stack. Need to integrate with
    # UI.
    # it "has an exception description" do
    #   error_inspector_output=<<-EOH
    # Error compiling /var/chef/cache/cookbooks/syntax-err/recipes/default.rb:
    # undefined method `this_is_not_a_valid_method' for Chef::Resource::File
    #
    # Cookbook trace:
    #   /var/chef/cache/cookbooks/syntax-err/recipes/default.rb:14:in `from_file'
    #   /var/chef/cache/cookbooks/syntax-err/recipes/default.rb:11:in `from_file'
    #
    # Most likely caused here:
    #   7:  # All rights reserved - Do Not Redistribute
    #   8:  #
    #   9:
    #  10:
    #  11:  file "/tmp/explode-me" do
    #  12:    mode 0655
    #  13:    owner "root"
    #  14>>   this_is_not_a_valid_method
    #  15:  end
    #  16:
    # EOH
    #   @resource_reporter.exception_description.should == error_inspector_output
    # end
  end

  context "when a resource fails before loading current state" do
    before do
      @exception = Exception.new
      @resource_reporter.resource_action_start(@new_resource, :create)
      @resource_reporter.resource_failed(@new_resource, :create, @exception)
    end

    it "collects the resource as an updated resource" do
      @resource_reporter.should have(1).updated_resources
    end

    it "collects the desired state of the resource" do
      update_record = @resource_reporter.updated_resources.first
      update_record.new_resource.should == @new_resource
    end

  end

  # TODO: make sure a resource that is skipped because of `not_if` doesn't
  # leave us in a bad state.

  context "once the a resource's current state is loaded" do
    before do
      @resource_reporter.resource_action_start(@new_resource, :create)
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

        update_record.current_resource.should == @current_resource
      end

      it "collects the new state of the resource" do
        update_record = @resource_reporter.updated_resources.first

        update_record.new_resource.should == @new_resource
      end

      context "and a subsequent resource fails before loading current resource" do
        before do
          @next_new_resource = Chef::Resource::Service.new("apache2")
          @exception = Exception.new
          @resource_reporter.resource_failed(@next_new_resource, :create, @exception)
        end

        it "collects the desired state of the failed resource" do
          failed_resource_update = @resource_reporter.updated_resources.last
          failed_resource_update.new_resource.should == @next_new_resource
        end

        it "does not have the current state of the failed resource" do
          failed_resource_update = @resource_reporter.updated_resources.last
          failed_resource_update.current_resource.should be_nil
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
        update_record.new_resource.should == @new_resource
      end

      it "collects the current state of the resource" do
        update_record = @resource_reporter.updated_resources.first
        update_record.current_resource.should == @current_resource
      end
    end

  end

  describe "when generating a report for the server" do
    context "for a successful client run" do
      before do
        # TODO: add inputs to generate expected output.

        # expected_data = {
        #    "action" : "end",
        #    "resources" : [
        #       {
        #         "type" : "file",
        #         "id" : "/etc/passwd",
        #         "name" : "User Defined Resource Block Name",
        #         "duration" : "1200",
        #         "result" : "modified",
        #         "before" : {
        #              "state" : "exists",
        #              "group" : "root",
        #              "owner" : "root",
        #              "checksum" : "xyz"
        #         },
        #         "after" : {
        #              "state" : "modified",
        #              "group" : "root",
        #              "owner" : "root",
        #              "checksum" : "abc"
        #         },
        #         "delta" : ""
        #      },
        #      {...}
        #     ],
        #    "status" : "success"
        #    "data" : ""
        # }

        @resource_reporter.resource_action_start(@new_resource, :create)
        @resource_reporter.resource_current_state_loaded(@new_resource, :create, @current_resource)
        @resource_reporter.resource_updated(@new_resource, :create)
        @resource_reporter.run_completed
        @report = @resource_reporter.report
        @first_update_report = @report["resources"].first
      end

      it "includes a list of updated resources" do
        @report.should have_key("resources")
      end

      it "includes an updated resource's type" do
        @first_update_report.should have_key("type")
      end

      it "includes an updated resource's initial state" do
        @first_update_report["before"].should == @current_resource.state
      end

      it "includes an updated resource's final state" do
        @first_update_report["after"].should == @new_resource.state
      end

      it "includes the resource's name" do
        @first_update_report["name"].should == @new_resource.name
      end

      it "includes the resource's id attribute" do
        @first_update_report["id"].should == @new_resource.identity
      end

      it "includes the elapsed time for the resource to converge" do
        @first_update_report["elapsed_time"].should be_within(0.1).of(0)
      end

      it "includes the action executed by the resource" do
        @first_update_report["action"].should == "create"
      end

    end

    context "for an unsuccessful run" do
    end

  end

end
