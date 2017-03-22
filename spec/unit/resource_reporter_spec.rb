#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Prajakta Purohit (<prajakta@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
#
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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
require "chef/resource_reporter"
require "socket"

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
    @rest_client = double("Chef::ServerAPI (mock)")
    allow(@rest_client).to receive(:post).and_return(true)
    @resource_reporter = Chef::ResourceReporter.new(@rest_client)
    @new_resource      = Chef::Resource::File.new("/tmp/a-file.txt")
    @cookbook_name = "monkey"
    @new_resource.cookbook_name = @cookbook_name
    @cookbook_version = double("Cookbook::Version", :version => "1.2.3")
    allow(@new_resource).to receive(:cookbook_version).and_return(@cookbook_version)
    @current_resource = Chef::Resource::File.new("/tmp/a-file.txt")
    @start_time = Time.new
    @end_time = Time.new + 20
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @run_status = Chef::RunStatus.new(@node, @events)
    @run_list = Chef::RunList.new
    @run_list << "recipe[lobster]" << "role[rage]" << "recipe[fist]"
    @expansion = Chef::RunList::RunListExpansion.new("_default", @run_list.run_list_items)
    @run_id = @run_status.run_id
    allow(Time).to receive(:now).and_return(@start_time, @end_time)
  end

  context "when first created" do

    it "has no updated resources" do
      expect(@resource_reporter.updated_resources.size).to eq(0)
    end

    it "reports a successful run" do
      expect(@resource_reporter.status).to eq("success")
    end

    it "assumes the resource history feature is supported" do
      expect(@resource_reporter.reporting_enabled?).to be_truthy
    end

    it "should have no error_descriptions" do
      expect(@resource_reporter.error_descriptions).to eq({})
      # @resource_reporter.error_descriptions.should be_empty
      # @resource_reporter.should have(0).error_descriptions
    end

  end

  context "after the chef run completes" do

    before do
    end

    it "reports a successful run" do
      skip "refactor how node gets set."
      expect(@resource_reporter.status).to eq("success")
    end
  end

  context "when chef fails" do
    before do
      allow(@rest_client).to receive(:raw_request).and_return({ "result" => "ok" })
      allow(@rest_client).to receive(:post).and_return({ "uri" => "https://example.com/reports/nodes/spitfire/runs/#{@run_id}" })

    end

    context "before converging any resources" do
      before do
        @resource_reporter.run_started(@run_status)
        @exception = Exception.new
        @resource_reporter.run_failed(@exception)
      end

      it "sets the run status to 'failure'" do
        expect(@resource_reporter.status).to eq("failure")
      end

      it "keeps the exception data" do
        expect(@resource_reporter.exception).to eq(@exception)
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
        expect(@resource_reporter.updated_resources.size).to eq(1)
      end

      it "collects the desired state of the resource" do
        update_record = @resource_reporter.updated_resources.first
        expect(update_record.new_resource).to eq(@new_resource)
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
          expect(@resource_reporter.updated_resources.size).to eq(0)
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
          expect(@resource_reporter.updated_resources.size).to eq(1)
        end

        it "collects the old state of the resource" do
          update_record = @resource_reporter.updated_resources.first
          expect(update_record.current_resource).to eq(@current_resource)
        end

        it "collects the new state of the resource" do
          update_record = @resource_reporter.updated_resources.first
          expect(update_record.new_resource).to eq(@new_resource)
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
            expect(failed_resource_update.new_resource).to eq(@next_new_resource)
          end

          it "does not have the current state of the failed resource" do
            failed_resource_update = @resource_reporter.updated_resources.last
            expect(failed_resource_update.current_resource).to be_nil
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
          expect(@resource_reporter.updated_resources.size).to eq(1)
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
          expect(@resource_reporter.updated_resources.size).to eq(1)
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
          expect(@resource_reporter.updated_resources.size).to eq(1)
        end

        it "collects the desired state of the resource" do
          update_record = @resource_reporter.updated_resources.first
          expect(update_record.new_resource).to eq(@new_resource)
        end

        it "collects the current state of the resource" do
          update_record = @resource_reporter.updated_resources.first
          expect(update_record.current_resource).to eq(@current_resource)
        end
      end

    end
  end

  describe "when generating a report for the server" do

    before do
      allow(@rest_client).to receive(:raw_request).and_return({ "result" => "ok" })
      allow(@rest_client).to receive(:post).and_return({ "uri" => "https://example.com/reports/nodes/spitfire/runs/#{@run_id}" })

      @resource_reporter.run_started(@run_status)
    end

    context "when the new_resource is sensitive" do
      before do
        @execute_resource = Chef::Resource::Execute.new("sensitive-resource")
        @execute_resource.name("sensitive-resource")
        @execute_resource.command('echo "password: SECRET"')
        @execute_resource.sensitive(true)
        @resource_reporter.resource_action_start(@execute_resource, :run)
        @resource_reporter.resource_current_state_loaded(@execute_resource, :run, @current_resource)
        @resource_reporter.resource_updated(@execute_resource, :run)
        @resource_reporter.resource_completed(@execute_resource)
        @run_status.stop_clock
        @report = @resource_reporter.prepare_run_data
        @first_update_report = @report["resources"].first
      end

      it "resource_name in prepared_run_data should be the same" do
        expect(@first_update_report["name"]).to eq("sensitive-resource")
      end

      it "resource_command in prepared_run_data should be blank" do
        expect(@first_update_report["after"]).to eq({ :command => "sensitive-resource", :user => nil })
      end
    end

    context "when the new_resource does not have a string for name and identity" do
      context "the new_resource name and id are nil" do
        before do
          @bad_resource = Chef::Resource::File.new("/tmp/nameless_file.txt")
          allow(@bad_resource).to receive(:name).and_return(nil)
          allow(@bad_resource).to receive(:identity).and_return(nil)
          allow(@bad_resource).to receive(:path).and_return(nil)
          @resource_reporter.resource_action_start(@bad_resource, :create)
          @resource_reporter.resource_current_state_loaded(@bad_resource, :create, @current_resource)
          @resource_reporter.resource_updated(@bad_resource, :create)
          @resource_reporter.resource_completed(@bad_resource)
          @run_status.stop_clock
          @report = @resource_reporter.prepare_run_data
          @first_update_report = @report["resources"].first
        end

        it "resource_name in prepared_run_data is a string" do
          expect(@first_update_report["name"].class).to eq(String)
        end

        it "resource_id in prepared_run_data is a string" do
          expect(@first_update_report["id"].class).to eq(String)
        end
      end

      context "the new_resource name and id are hashes" do
        before do
          @bad_resource = Chef::Resource::File.new("/tmp/filename_as_hash.txt")
          allow(@bad_resource).to receive(:name).and_return({ :foo => :bar })
          allow(@bad_resource).to receive(:identity).and_return({ :foo => :bar })
          allow(@bad_resource).to receive(:path).and_return({ :foo => :bar })
          @resource_reporter.resource_action_start(@bad_resource, :create)
          @resource_reporter.resource_current_state_loaded(@bad_resource, :create, @current_resource)
          @resource_reporter.resource_updated(@bad_resource, :create)
          @resource_reporter.resource_completed(@bad_resource)
          @run_status.stop_clock
          @report = @resource_reporter.prepare_run_data
          @first_update_report = @report["resources"].first
        end
        # Ruby 1.8.7 flattens out hash to string using join instead of inspect, resulting in
        # irb(main):001:0> {:foo => :bar}.to_s
        # => "foobar"
        # instead of the expected
        # irb(main):001:0> {:foo => :bar}.to_s
        # => "{:foo=>:bar}"
        # Hence checking for the class instead of the actual value.
        it "resource_name in prepared_run_data is a string" do
          expect(@first_update_report["name"].class).to eq(String)
        end

        it "resource_id in prepared_run_data is a string" do
          expect(@first_update_report["id"].class).to eq(String)
        end
      end
    end

    shared_examples_for "a successful client run" do
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
        @resource_reporter.resource_action_start(new_resource, :create)
        @resource_reporter.resource_current_state_loaded(new_resource, :create, current_resource)
        @resource_reporter.resource_updated(new_resource, :create)
        @resource_reporter.resource_completed(new_resource)
        @run_status.stop_clock
        @report = @resource_reporter.prepare_run_data
        @first_update_report = @report["resources"].first
      end

      it "includes the run's status" do
        expect(@report).to have_key("status")
      end

      it "includes a list of updated resources" do
        expect(@report).to have_key("resources")
      end

      it "includes an updated resource's type" do
        expect(@first_update_report).to have_key("type")
      end

      it "includes an updated resource's initial state" do
        expect(@first_update_report["before"]).to eq(current_resource.state_for_resource_reporter)
      end

      it "includes an updated resource's final state" do
        expect(@first_update_report["after"]).to eq(new_resource.state_for_resource_reporter)
      end

      it "includes the resource's name" do
        expect(@first_update_report["name"]).to eq(new_resource.name)
      end

      it "includes the resource's id attribute" do
        expect(@first_update_report["id"]).to eq(new_resource.identity)
      end

      it "includes the elapsed time for the resource to converge" do
        # TODO: API takes integer number of milliseconds as a string. This
        # should be an int.
        expect(@first_update_report).to have_key("duration")
        expect(@first_update_report["duration"].to_i).to be_within(100).of(0)
      end

      it "includes the action executed by the resource" do
        # TODO: rename as "action"
        expect(@first_update_report["result"]).to eq("create")
      end

      it "includes the cookbook name of the resource" do
        expect(@first_update_report).to have_key("cookbook_name")
        expect(@first_update_report["cookbook_name"]).to eq(@cookbook_name)
      end

      it "includes the cookbook version of the resource" do
        expect(@first_update_report).to have_key("cookbook_version")
        expect(@first_update_report["cookbook_version"]).to eq("1.2.3")
      end

      it "includes the total resource count" do
        expect(@report).to have_key("total_res_count")
        expect(@report["total_res_count"]).to eq("1")
      end

      it "includes the data hash" do
        expect(@report).to have_key("data")
        expect(@report["data"]).to eq({})
      end

      it "includes the run_list" do
        expect(@report).to have_key("run_list")
        expect(@report["run_list"]).to eq(Chef::JSONCompat.to_json(@run_status.node.run_list))
      end

      it "includes the expanded_run_list" do
        expect(@report).to have_key("expanded_run_list")
      end

      it "includes the end_time" do
        expect(@report).to have_key("end_time")
        expect(@report["end_time"]).to eq(@run_status.end_time.to_s)
      end

    end

    context "when the resource is a File" do
      let(:new_resource) { @new_resource }
      let(:current_resource) { @current_resource }

      it_should_behave_like "a successful client run"
    end

    context "when the resource is a RegistryKey with binary data" do
      let(:new_resource) do
        resource = Chef::Resource::RegistryKey.new('Wubba\Lubba\Dub\Dubs')
        resource.values([ { :name => "rick", :type => :binary, :data => 255.chr * 1 } ])
        allow(resource).to receive(:cookbook_name).and_return(@cookbook_name)
        allow(resource).to receive(:cookbook_version).and_return(@cookbook_version)
        resource
      end

      let(:current_resource) do
        resource = Chef::Resource::RegistryKey.new('Wubba\Lubba\Dub\Dubs')
        resource.values([ { :name => "rick", :type => :binary, :data => 255.chr * 1 } ])
        resource
      end

      it_should_behave_like "a successful client run"
    end

    context "for an unsuccessful run" do

      before do
        @backtrace = ["foo.rb:1 in `foo!'", "bar.rb:2 in `bar!", "'baz.rb:3 in `baz!'"]
        @node = Chef::Node.new
        @node.name("spitfire")
        @exception = ArgumentError.new
        allow(@exception).to receive(:inspect).and_return("Net::HTTPServerException")
        allow(@exception).to receive(:message).and_return("Object not found")
        allow(@exception).to receive(:backtrace).and_return(@backtrace)
        @resource_reporter.run_list_expand_failed(@node, @exception)
        @resource_reporter.run_failed(@exception)
        @report = @resource_reporter.prepare_run_data
      end

      it "includes the exception type in the event data" do
        expect(@report).to have_key("data")
        expect(@report["data"]["exception"]).to have_key("class")
        expect(@report["data"]["exception"]["class"]).to eq("Net::HTTPServerException")
      end

      it "includes the exception message in the event data" do
        expect(@report["data"]["exception"]).to have_key("message")
        expect(@report["data"]["exception"]["message"]).to eq("Object not found")
      end

      it "includes the exception trace in the event data" do
        expect(@report["data"]["exception"]).to have_key("backtrace")
        expect(@report["data"]["exception"]["backtrace"]).to eq(Chef::JSONCompat.to_json(@backtrace))
      end

      it "includes the error inspector output in the event data" do
        expect(@report["data"]["exception"]).to have_key("description")
        expect(@report["data"]["exception"]["description"]).to include({ "title" => "Error expanding the run_list:", "sections" => [{ "Unexpected Error:" => "ArgumentError: Object not found" }] })
      end

    end

    context "when new_resource does not have a cookbook_name" do
      before do
        @bad_resource = Chef::Resource::File.new("/tmp/a-file.txt")
        @bad_resource.cookbook_name = nil

        @resource_reporter.resource_action_start(@bad_resource, :create)
        @resource_reporter.resource_current_state_loaded(@bad_resource, :create, @current_resource)
        @resource_reporter.resource_updated(@bad_resource, :create)
        @resource_reporter.resource_completed(@bad_resource)
        @run_status.stop_clock
        @report = @resource_reporter.prepare_run_data
        @first_update_report = @report["resources"].first
      end

      it "includes an updated resource's initial state" do
        expect(@first_update_report["before"]).to eq(@current_resource.state_for_resource_reporter)
      end

      it "includes an updated resource's final state" do
        expect(@first_update_report["after"]).to eq(@new_resource.state_for_resource_reporter)
      end

      it "includes the resource's name" do
        expect(@first_update_report["name"]).to eq(@new_resource.name)
      end

      it "includes the resource's id attribute" do
        expect(@first_update_report["id"]).to eq(@new_resource.identity)
      end

      it "includes the elapsed time for the resource to converge" do
        # TODO: API takes integer number of milliseconds as a string. This
        # should be an int.
        expect(@first_update_report).to have_key("duration")
        expect(@first_update_report["duration"].to_i).to be_within(100).of(0)
      end

      it "includes the action executed by the resource" do
        # TODO: rename as "action"
        expect(@first_update_report["result"]).to eq("create")
      end

      it "does not include a cookbook name for the resource" do
        expect(@first_update_report).not_to have_key("cookbook_name")
      end

      it "does not include a cookbook version for the resource" do
        expect(@first_update_report).not_to have_key("cookbook_version")
      end
    end

    context "when including a resource that overrides Resource#state" do
      before do
        @current_state_resource = Chef::Resource::WithState.new("Stateful", @run_context)
        @current_state_resource.state = nil

        @new_state_resource = Chef::Resource::WithState.new("Stateful", @run_context)
        @new_state_resource.state = "Running"
        @resource_reporter.resource_action_start(@new_state_resource, :create)
        @resource_reporter.resource_current_state_loaded(@new_state_resource, :create, @current_state_resource)
        @resource_reporter.resource_updated(@new_state_resource, :create)
        @resource_reporter.resource_completed(@new_state_resource)
        @run_status.stop_clock
        @report = @resource_reporter.prepare_run_data
        @first_update_report = @report["resources"].first
      end

      it "sets before to {} instead of nil" do
        expect(@first_update_report).to have_key("before")
        expect(@first_update_report["before"]).to eq({})
      end

      it "sets after to {} instead of 'Running'" do
        expect(@first_update_report).to have_key("after")
        expect(@first_update_report["after"]).to eq({})
      end
    end

  end

  describe "when updating resource history on the server" do
    before do
      @resource_reporter.run_started(@run_status)
      @run_status.start_clock
    end

    context "when the server does not support storing resource history" do
      before do
        # 404 getting the run_id
        @response = Net::HTTPNotFound.new("a response body", "404", "Not Found")
        @error = Net::HTTPServerException.new("404 message", @response)
        expect(@rest_client).to receive(:post).
          with("reports/nodes/spitfire/runs", { :action => :start, :run_id => @run_id,
                                                :start_time => @start_time.to_s },
               { "X-Ops-Reporting-Protocol-Version" => Chef::ResourceReporter::PROTOCOL_VERSION }).
          and_raise(@error)
      end

      it "assumes the feature is not enabled" do
        @resource_reporter.run_started(@run_status)
        expect(@resource_reporter.reporting_enabled?).to be_falsey
      end

      it "does not send a resource report to the server" do
        @resource_reporter.run_started(@run_status)
        expect(@rest_client).not_to receive(:post)
        @resource_reporter.run_completed(@node)
      end

      it "prints an error about the 404" do
        expect(Chef::Log).to receive(:debug).with(/404/)
        @resource_reporter.run_started(@run_status)
      end

    end

    context "when the server returns a 500 to the client" do
      before do
        # 500 getting the run_id
        @response = Net::HTTPInternalServerError.new("a response body", "500", "Internal Server Error")
        @error = Net::HTTPServerException.new("500 message", @response)
        expect(@rest_client).to receive(:post).
          with("reports/nodes/spitfire/runs", { :action => :start, :run_id => @run_id, :start_time => @start_time.to_s },
               { "X-Ops-Reporting-Protocol-Version" => Chef::ResourceReporter::PROTOCOL_VERSION }).
          and_raise(@error)
      end

      it "assumes the feature is not enabled" do
        @resource_reporter.run_started(@run_status)
        expect(@resource_reporter.reporting_enabled?).to be_falsey
      end

      it "does not send a resource report to the server" do
        @resource_reporter.run_started(@run_status)
        expect(@rest_client).not_to receive(:post)
        @resource_reporter.run_completed(@node)
      end

      it "prints an error about the error" do
        expect(Chef::Log).to receive(:info).with(/500/)
        @resource_reporter.run_started(@run_status)
      end
    end

    context "when the server returns a 500 to the client and enable_reporting_url_fatals is true" do
      before do
        @enable_reporting_url_fatals = Chef::Config[:enable_reporting_url_fatals]
        Chef::Config[:enable_reporting_url_fatals] = true
        # 500 getting the run_id
        @response = Net::HTTPInternalServerError.new("a response body", "500", "Internal Server Error")
        @error = Net::HTTPServerException.new("500 message", @response)
        expect(@rest_client).to receive(:post).
          with("reports/nodes/spitfire/runs", { :action => :start, :run_id => @run_id, :start_time => @start_time.to_s },
               { "X-Ops-Reporting-Protocol-Version" => Chef::ResourceReporter::PROTOCOL_VERSION }).
          and_raise(@error)
      end

      after do
        Chef::Config[:enable_reporting_url_fatals] = @enable_reporting_url_fatals
      end

      it "fails the run and prints an message about the error" do
        expect(Chef::Log).to receive(:error).with(/500/)
        expect do
          @resource_reporter.run_started(@run_status)
        end.to raise_error(Net::HTTPServerException)
      end
    end

    context "after creating the run history document" do
      before do
        response = { "uri" => "https://example.com/reports/nodes/spitfire/runs/@run_id" }
        expect(@rest_client).to receive(:post).
          with("reports/nodes/spitfire/runs", { :action => :start, :run_id => @run_id, :start_time => @start_time.to_s },
               { "X-Ops-Reporting-Protocol-Version" => Chef::ResourceReporter::PROTOCOL_VERSION }).
          and_return(response)
        @resource_reporter.run_started(@run_status)
      end

      it "creates a run document on the server at the start of the run" do
        expect(@resource_reporter.run_id).to eq(@run_id)
      end

      it "updates the run document with resource updates at the end of the run" do
        # update some resources...
        @resource_reporter.resource_action_start(@new_resource, :create)
        @resource_reporter.resource_current_state_loaded(@new_resource, :create, @current_resource)
        @resource_reporter.resource_updated(@new_resource, :create)

        allow(@resource_reporter).to receive(:end_time).and_return(@end_time)
        @expected_data = @resource_reporter.prepare_run_data

        response = { "result" => "ok" }

        expect(@rest_client).to receive(:raw_request).ordered do |method, url, headers, data|
          expect(method).to eq(:POST)
          expect(headers).to eq({ "Content-Encoding" => "gzip",
                                  "X-Ops-Reporting-Protocol-Version" => Chef::ResourceReporter::PROTOCOL_VERSION,
          })
          data_stream = Zlib::GzipReader.new(StringIO.new(data))
          data = data_stream.read
          expect(data).to eq(Chef::JSONCompat.to_json(@expected_data))
          response
        end

        @resource_reporter.run_completed(@node)
      end
    end

    context "when data report post is enabled and the server response fails" do
      before do
        @enable_reporting_url_fatals = Chef::Config[:enable_reporting_url_fatals]
        Chef::Config[:enable_reporting_url_fatals] = true
      end

      after do
        Chef::Config[:enable_reporting_url_fatals] = @enable_reporting_url_fatals
      end

      it "should log 4xx errors" do
        response = Net::HTTPClientError.new("forbidden", "403", "Forbidden")
        error = Net::HTTPServerException.new("403 message", response)
        allow(@rest_client).to receive(:raw_request).and_raise(error)
        expect(Chef::Log).to receive(:error).with(/403/)

        @resource_reporter.post_reporting_data
      end

      it "should log error 5xx errors" do
        response = Net::HTTPServerError.new("internal error", "500", "Internal Server Error")
        error = Net::HTTPFatalError.new("500 message", response)
        allow(@rest_client).to receive(:raw_request).and_raise(error)
        expect(Chef::Log).to receive(:error).with(/500/)

        @resource_reporter.post_reporting_data
      end

      it "should log if a socket error happens" do
        allow(@rest_client).to receive(:raw_request).and_raise(SocketError.new("test socket error"))
        expect(Chef::Log).to receive(:error).with(/test socket error/)

        @resource_reporter.post_reporting_data

      end

      it "should raise if an unkwown error happens" do
        allow(@rest_client).to receive(:raw_request).and_raise(Exception.new)

        expect do
          @resource_reporter.post_reporting_data
        end.to raise_error(Exception)
      end
    end
  end
end
