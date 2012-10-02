#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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
  before(:all) do
    @reporting_toggle_default = Chef::Config[:enable_reporting]
    Chef::Config[:enable_reporting] = true
  end

  after(:all) do
    Chef::Config[:enable_reporting] = @reporting_toggle_default
  end

  before do
    @node = Chef::Node.new
    @node.name("spitfire")
    @rest_client = mock("Chef::REST (mock)")
    @rest_client.stub!(:post_rest).and_return(true)
    @resource_reporter = Chef::ResourceReporter.new(@rest_client)
    @new_resource      = Chef::Resource::File.new("/tmp/a-file.txt")
    @new_resource.cookbook_name = "monkey"
    @cookbook_version = mock("Cookbook::Version", :version => "1.2.3")
    @new_resource.stub!(:cookbook_version).and_return(@cookbook_version)
    @current_resource  = Chef::Resource::File.new("/tmp/a-file.txt")
  end

  context "when first created" do

    it "has no updated resources" do
      @resource_reporter.should have(0).updated_resources
    end

    it "reports a successful run" do
      @resource_reporter.status.should == "success"
    end

    it "assumes the resource history feature is supported" do
      @resource_reporter.reporting_enabled?.should be_true
    end

    it "should have no error_descriptions" do
      @resource_reporter.error_descriptions.should eq({})
      # @resource_reporter.error_descriptions.should be_empty
      # @resource_reporter.should have(0).error_descriptions
    end

  end

  context "after the chef run completes" do

    before do
    end

    it "reports a successful run" do
      pending "refactor how node gets set."
      @resource_reporter.status.should == "success"
    end
  end

  context "when chef fails" do
    before do
      @rest_client.stub!(:create_url).and_return("reports/nodes/spitfire/runs/ABC123");
      @rest_client.stub!(:raw_http_request).and_return({"result"=>"ok"});
      @rest_client.stub!(:post_rest).and_return({"uri"=>"https://example.com/reports/nodes/spitfire/runs/ABC123"});

      @resource_reporter.node_load_completed(@node, :expanded_run_list, :config)
    end

    context "before converging any resources" do
      before do
        @exception = Exception.new
        @resource_reporter.run_failed(@exception)
      end
      
      it "sets the run status to 'failure'" do
        @resource_reporter.status.should == "failure"
      end
      
      it "keeps the exception data" do
        @resource_reporter.exception.should == @exception
      end
    end

    context "when a resource fails before loading current state" do
      before do
        @exception = Exception.new
        @exception.set_backtrace(caller)
        @resource_reporter.resource_action_start(@new_resource, :create)
        @resource_reporter.resource_failed(@new_resource, :create, @exception)
        @resource_reporter.resource_completed(@new_resource)
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
          @resource_reporter.resource_completed(@new_resource)
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
            @exception.set_backtrace(caller)
            @resource_reporter.resource_failed(@next_new_resource, :create, @exception)
            @resource_reporter.resource_completed(@next_new_resource)
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
    
      # Some providers, such as RemoteDirectory and some LWRPs use other
      # resources for their implementation. These should be hidden from reporting
      # since we only care about the top-level resource and not the sub-resources
      # used for implementation.
      context "and a nested resource is updated" do
        before do
          @implementation_resource = Chef::Resource::CookbookFile.new("/preseed-file.txt")
        @resource_reporter.resource_action_start(@implementation_resource , :create)
        @resource_reporter.resource_current_state_loaded(@implementation_resource, :create, @implementation_resource)
        @resource_reporter.resource_updated(@implementation_resource, :create)
        @resource_reporter.resource_completed(@implementation_resource)
        @resource_reporter.resource_updated(@new_resource, :create)
        @resource_reporter.resource_completed(@new_resource)
      end

        it "does not collect data about the nested resource" do
          @resource_reporter.should have(1).updated_resources
        end
      end

      context "and a nested resource runs but is not updated" do
        before do
          @implementation_resource = Chef::Resource::CookbookFile.new("/preseed-file.txt")
          @resource_reporter.resource_action_start(@implementation_resource , :create)
          @resource_reporter.resource_current_state_loaded(@implementation_resource, :create, @implementation_resource)
          @resource_reporter.resource_up_to_date(@implementation_resource, :create)
          @resource_reporter.resource_completed(@implementation_resource)
          @resource_reporter.resource_updated(@new_resource, :create)
          @resource_reporter.resource_completed(@new_resource)
        end
        
        it "does not collect data about the nested resource" do
          @resource_reporter.should have(1).updated_resources
        end
      end

      context "and the resource failed to converge" do
        before do
          @exception = Exception.new
          @exception.set_backtrace(caller)
          @resource_reporter.resource_failed(@new_resource, :create, @exception)
          @resource_reporter.resource_completed(@new_resource)
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
  end

  describe "when generating a report for the server" do

    before do
      @rest_client.stub!(:create_url).and_return("reports/nodes/spitfire/runs/ABC123");
      @rest_client.stub!(:raw_http_request).and_return({"result"=>"ok"});
      @rest_client.stub!(:post_rest).and_return({"uri"=>"https://example.com/reports/nodes/spitfire/runs/ABC123"});
      
      @resource_reporter.node_load_completed(@node, :expanded_run_list, :config)
    end
    
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
        @resource_reporter.resource_completed(@new_resource)
        @report = @resource_reporter.prepare_run_data
        @first_update_report = @report["resources"].first
      end

      it "includes the run's status" do
        @report.should have_key("status")
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
        # TODO: API takes integer number of milliseconds as a string. This
        # should be an int.
        @first_update_report.should have_key("duration")
        @first_update_report["duration"].to_i.should be_within(100).of(0)
      end

      it "includes the action executed by the resource" do
        # TODO: rename as "action"
        @first_update_report["result"].should == "create"
      end

      it "includes the cookbook name of the resource" do
        @first_update_report.should have_key("cookbook_name")
        @first_update_report["cookbook_name"].should == "monkey"
      end

      it "includes the cookbook version of the resource" do
        @first_update_report.should have_key("cookbook_version")
        @first_update_report["cookbook_version"].should == "1.2.3"
      end

      it "includes the total resource count" do
        @report.should have_key("total_res_count")
        @report["total_res_count"].should == "1"
      end

      it "includes the data hash" do
        @report.should have_key("data")
        @report["data"].should == {}
      end

      it "includes the run_list" do
        @report.should have_key("run_list")
        @report["run_list"].should == @node.run_list.to_json
      end
    end

    context "for an unsuccessful run" do

      before do
        @backtrace = ["foo.rb:1 in `foo!'","bar.rb:2 in `bar!","'baz.rb:3 in `baz!'"]
        @node = Chef::Node.new
        @node.name("spitfire")
        @exception = mock("ArgumentError")
        @exception.stub!(:inspect).and_return("Net::HTTPServerException")
        @exception.stub!(:message).and_return("Object not found")
        @exception.stub!(:backtrace).and_return(@backtrace)
        @resource_reporter.run_list_expand_failed(@node, @exception)
        @resource_reporter.run_failed(@exception)
        @report = @resource_reporter.prepare_run_data
      end

      it "includes the exception type in the event data" do
        @report.should have_key("data")
        @report["data"]["exception"].should have_key("class")
        @report["data"]["exception"]["class"].should == "Net::HTTPServerException"
      end

      it "includes the exception message in the event data" do
        @report["data"]["exception"].should have_key("message")
        @report["data"]["exception"]["message"].should == "Object not found"
      end

      it "includes the exception trace in the event data" do
        @report["data"]["exception"].should have_key("backtrace")
        @report["data"]["exception"]["backtrace"].should == @backtrace.to_json
      end

      it "includes the error inspector output in the event data" do
        @report["data"]["exception"].should have_key("description")
        @report["data"]["exception"]["description"].should include({"title"=>"Error expanding the run_list:", "sections"=>[["Unexpected Error:", "RSpec::Mocks::Mock: Object not found"]]})
      end

    end

  end

  describe "when updating resource history on the server" do
    before do
    end

    context "when the server does not support storing resource history" do
      before do
        # 404 getting the run_id
        @response = Net::HTTPNotFound.new("a response body", "404", "Not Found")
        @error = Net::HTTPServerException.new("404 message", @response)
        @rest_client.should_receive(:post_rest).
          with("reports/nodes/spitfire/runs", {:action => :begin}).
          and_raise(@error)
        @resource_reporter.node_load_completed(@node, :expanded_run_list, :config)
      end

      it "assumes the feature is not enabled" do
        @resource_reporter.reporting_enabled?.should be_false
      end

      it "does not send a resource report to the server" do
        @rest_client.should_not_receive(:post_rest)
        @resource_reporter.run_completed(@node)
      end

    end

    context "after creating the run history document" do
      before do
        response = {"uri"=>"https://example.com/reports/nodes/spitfire/runs/ABC123"}
        @rest_client.should_receive(:post_rest).
          with("reports/nodes/spitfire/runs", {:action => :begin}).
          and_return(response)

        @resource_reporter.node_load_completed(@node, :expanded_run_list, :config)
      end

      it "creates a run document on the server at the start of the run" do
        @resource_reporter.run_id.should == "ABC123"
      end

      it "updates the run document with resource updates at the end of the run" do
        # update some resources...
        @resource_reporter.resource_action_start(@new_resource, :create)
        @resource_reporter.resource_current_state_loaded(@new_resource, :create, @current_resource)
        @resource_reporter.resource_updated(@new_resource, :create)

        @expected_data = @resource_reporter.prepare_run_data
        @expected_data["action"] = "end"

        post_url = "https://chef_server/example_url"
        response = {"result"=>"ok"}

        @rest_client.should_receive(:create_url).
          with("reports/nodes/spitfire/runs/ABC123").
          ordered.
          and_return(post_url)
        @rest_client.should_receive(:raw_http_request).ordered do |method, url, headers, data|
          method.should eq(:POST)
          url.should eq(post_url)
          headers.should eq({'Content-Encoding' => 'gzip'})
          data_stream = Zlib::GzipReader.new(StringIO.new(data))
          data = data_stream.read
          data.should eq(@expected_data.to_json)
          response
        end

        @resource_reporter.run_completed(@node)
      end
    end
  end

end
