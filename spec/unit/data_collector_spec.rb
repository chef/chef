#
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/data_collector"
require "socket"

#
# FIXME FIXME FIXME:  What we need to do here is have the ability to construct a real resource collection
# with some test resources that will correctly be up-to-date/updated/skipped/failed/unprocessed and really
# converge a client with them (sort of chefspec-like construction of a Chef::Client but with the actions
# actually running -- another testing requirement similar to the integration testing framework in cheffish as well)
#
describe Chef::DataCollector do
  let(:node) { Chef::Node.new }

  let(:rest_client) { double("Chef::ServerAPI (mock)") }

  let(:data_collector) { Chef::DataCollector::Reporter.new(events) }

  let(:new_resource) do
    new_resource = Chef::Resource::File.new("/tmp/a-file.txt")
    new_resource.checksum nil
    # This next line is a hack to work around the fact that the name property will not have been autovivified yet
    # in these unit tests which breaks some assumptions.  Really the Formatters::ErrorMapper.resource_failed and
    # related APIs need to properly walk and get properties on the resource rather than walking through instance
    # variables, but the ErrorMappers probably pre-date the conversion to properties.  But this next line is necesary
    # to populate the name_property instance variable (which will happen naturally during the course of running the
    # provider, so I don't think this is a user-visibile bug).
    new_resource.path
    new_resource
  end

  let(:current_resource) do
    current_resource = Chef::Resource::File.new("/tmp/a-file.txt")
    current_resource.checksum "1234123412341234123412341234123412341234123412341234123412341234"
    current_resource
  end

  let(:after_resource) do
    after_resource = Chef::Resource::File.new("/tmp/a-file.txt")
    after_resource.checksum "6789678967896789678967896789678967896789678967896789678967896789"
    after_resource
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:run_status) { Chef::RunStatus.new(node, events) }

  let(:start_time) { Time.new }

  let(:end_time) { Time.new + 20 }

  let(:run_list) { node.run_list }

  let(:cookbooks) { node.fetch("cookbooks", {}) }

  let(:run_id) { run_status.run_id }

  let(:expansion) { Chef::RunList::RunListExpansion.new("_default", run_list.run_list_items) }

  let(:cookbook_name) { "monkey" }

  let(:recipe_name) { "atlas" }

  let(:node_name) { "spitfire" }

  let(:cookbook_version) { double("Cookbook::Version", version: "1.2.3") }

  let(:resource_record) { [] }

  let(:exception) { nil }

  let(:action_collection) { Chef::ActionCollection.new(events) }

  let(:expected_node) { node }

  let(:expected_expansion) { expansion }

  let(:expected_run_list) { run_list.for_json }

  let(:node_uuid) { "779196c6-f94f-4501-9dae-af8081ab4d3a" }

  let(:request_id) { "5db5d686-d18d-4234-a86a-28848c35dfc2" }

  before do
    allow(Time).to receive(:now).and_return(start_time, end_time)
    allow(Chef::HTTP::SimpleJSON).to receive(:new).and_return(rest_client)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest_client)
    node.name(node_name) unless node.is_a?(Hash)
    new_resource.cookbook_name = cookbook_name
    new_resource.recipe_name = recipe_name
    allow(new_resource).to receive(:cookbook_version).and_return(cookbook_version)

    run_list << "recipe[lobster]" << "role[rage]" << "recipe[fist]"
    events.register(data_collector)
    events.register(action_collection)
    run_status.run_id = request_id
    events.run_start(Chef::VERSION, run_status)
    Chef::Config[:chef_guid] = node_uuid
    # we're guaranteed that those events are processed or else the data collector has no hope
    # all other events could see the chef-client crash before executing them and the data collector
    # still needs to work in those cases, so must come later, and the failure cases must be tested.
  end

  def expect_start_message(keys = nil)
    keys ||= {
      "chef_server_fqdn" => "localhost",
      "entity_uuid" => node_uuid,
      "id" => request_id,
      "message_type" => "run_start",
      "message_version" => "1.0.0",
      "node_name" => node_name,
      "organization_name" => "unknown_organization",
      "run_id" => request_id,
      "source" => "chef_client",
      "start_time" => start_time.utc.iso8601,
    }
    expect(rest_client).to receive(:post).with(
      nil,
      hash_including(keys),
      { "Content-Type" => "application/json" }
    )
  end

  def expect_converge_message(keys)
    keys["message_type"] = "run_converge"
    keys["message_version"] = "1.1.0"
    # if (keys.key?("node") && !keys["node"].empty?)
    #   expect(rest_client).to receive(:post) do |_a, hash, _b|
    #     require 'pry'; binding.pry
    #   end
    # else
    expect(rest_client).to receive(:post).with(
      nil,
      hash_including(keys),
      { "Content-Type" => "application/json" }
    )
    # end
  end

  def resource_has_diff(new_resource, status)
    new_resource.respond_to?(:diff) && %w{updated failed}.include?(status)
  end

  def resource_record_for(new_resource, before_resource, after_resource, action, status, duration)
    {
      "after" => after_resource&.state_for_resource_reporter || {},
      "before" => before_resource&.state_for_resource_reporter || {},
      "cookbook_name" => cookbook_name,
      "cookbook_version" => cookbook_version.version,
      "delta" => resource_has_diff(new_resource, status) ? new_resource.diff : "",
      "duration" => duration,
      "id" => new_resource.identity,
      "ignore_failure" => new_resource.ignore_failure,
      "name" => new_resource.name,
      "recipe_name" => recipe_name,
      "result" => action.to_s,
      "status" => status,
      "type" => new_resource.resource_name.to_sym,
    }
  end

  def send_run_failed_or_completed_event
    status == "success" ? events.run_completed(node, run_status) : events.run_failed(exception, run_status)
  end

  shared_examples_for "sends a converge message" do
    it "has a chef_server_fqdn" do
      expect_converge_message("chef_server_fqdn" => "localhost")
      send_run_failed_or_completed_event
    end

    it "has a start_time" do
      expect_converge_message("start_time" => start_time.utc.iso8601)
      send_run_failed_or_completed_event
    end

    it "has a end_time" do
      expect_converge_message("end_time" => end_time.utc.iso8601)
      send_run_failed_or_completed_event
    end

    it "has a entity_uuid" do
      expect_converge_message("entity_uuid" => node_uuid)
      send_run_failed_or_completed_event
    end

    it "has a expanded_run_list" do
      expect_converge_message("expanded_run_list" => expected_expansion)
      send_run_failed_or_completed_event
    end

    it "has a node" do
      expect_converge_message("node" => expected_node.is_a?(Chef::Node) ? expected_node.data_for_save : expected_node)
      send_run_failed_or_completed_event
    end

    it "has a node_name" do
      expect_converge_message("node_name" => node_name)
      send_run_failed_or_completed_event
    end

    it "has an organization" do
      expect_converge_message("organization_name" => "unknown_organization")
      send_run_failed_or_completed_event
    end

    it "has a policy_group" do
      expect_converge_message("policy_group" => nil)
      send_run_failed_or_completed_event
    end

    it "has a policy_name" do
      expect_converge_message("policy_name" => nil)
      send_run_failed_or_completed_event
    end

    it "has a run_id" do
      expect_converge_message("run_id" => request_id)
      send_run_failed_or_completed_event
    end

    it "has a run_list" do
      expect_converge_message("run_list" => expected_run_list)
      send_run_failed_or_completed_event
    end

    it "has a cookbooks" do
      expect_converge_message("cookbooks" => cookbooks)
      send_run_failed_or_completed_event
    end

    it "has a source" do
      expect_converge_message("source" => "chef_client")
      send_run_failed_or_completed_event
    end

    it "has a status" do
      expect_converge_message("status" => status)
      send_run_failed_or_completed_event
    end

    it "has no deprecations" do
      expect_converge_message("deprecations" => [])
      send_run_failed_or_completed_event
    end

    it "has an error field" do
      if exception
        expect_converge_message(
          "error" => {
            "class" => exception.class,
            "message" => exception.message,
            "backtrace" => exception.backtrace,
            "description" => error_description,
          }
        )
      else
        expect(rest_client).to receive(:post).with(
          nil,
          hash_excluding("error"),
          { "Content-Type" => "application/json" }
        )
      end
      send_run_failed_or_completed_event
    end

    it "has a total resource count of zero" do
      expect_converge_message("total_resource_count" => total_resource_count)
      send_run_failed_or_completed_event
    end

    it "has a updated resource count of zero" do
      expect_converge_message("updated_resource_count" => updated_resource_count)
      send_run_failed_or_completed_event
    end

    it "includes the resource record" do
      expect_converge_message("resources" => resource_record)
      send_run_failed_or_completed_event
    end
  end

  describe "when the run fails during node load" do
    let(:exception) { Exception.new("imperial to metric conversion error") }
    let(:error_description) { Chef::Formatters::ErrorMapper.registration_failed(node_name, exception, Chef::Config).for_json }
    let(:total_resource_count) { 0 }
    let(:updated_resource_count) { 0 }
    let(:status) { "failure" }
    let(:expected_node) { {} } # no node because that failed
    let(:expected_run_list) { [] } # no run_list without a node
    let(:expected_expansion) { {} } # no run_list expansion without a run_list
    let(:resource_record) { [] } # and certainly no resources

    before do
      events.registration_failed(node_name, exception, Chef::Config)
      run_status.stop_clock
      run_status.exception = exception
      expect_start_message
    end

    it_behaves_like "sends a converge message"
  end

  describe "when the run fails during node load" do
    let(:exception) { Exception.new("imperial to metric conversion error") }
    let(:error_description) { Chef::Formatters::ErrorMapper.node_load_failed(node_name, exception, Chef::Config).for_json }
    let(:total_resource_count) { 0 }
    let(:updated_resource_count) { 0 }
    let(:status) { "failure" }
    let(:expected_node) { {} } # no node because that failed
    let(:expected_run_list) { [] } # no run_list without a node
    let(:expected_expansion) { {} } # no run_list expansion without a run_list
    let(:resource_record) { [] } # and certainly no resources

    before do
      events.node_load_failed(node_name, exception, Chef::Config)
      run_status.stop_clock
      run_status.exception = exception
      expect_start_message
    end

    it_behaves_like "sends a converge message"
  end

  describe "when the run fails during run_list_expansion" do
    let(:exception) { Exception.new("imperial to metric conversion error") }
    let(:error_description) { Chef::Formatters::ErrorMapper.run_list_expand_failed(node, exception).for_json }
    let(:total_resource_count) { 0 }
    let(:updated_resource_count) { 0 }
    let(:status) { "failure" }
    let(:expected_expansion) { {} } # no run_list expanasion when it failed
    let(:resource_record) { [] } # and no resources

    before do
      events.node_load_success(node)
      run_status.node = node
      events.run_list_expand_failed(node, exception)
      run_status.stop_clock
      run_status.exception = exception
      expect_start_message
    end

    it_behaves_like "sends a converge message"
  end

  describe "when the run fails during cookbook resolution" do
    let(:exception) { Exception.new("imperial to metric conversion error") }
    let(:error_description) { Chef::Formatters::ErrorMapper.cookbook_resolution_failed(node, exception).for_json }
    let(:total_resource_count) { 0 }
    let(:updated_resource_count) { 0 }
    let(:status) { "failure" }
    let(:resource_record) { [] } # and no resources

    before do
      events.node_load_success(node)
      run_status.node = node
      events.run_list_expanded(expansion)
      run_status.start_clock
      expect_start_message
      events.cookbook_resolution_failed(node, exception)
      run_status.stop_clock
      run_status.exception = exception
    end

    it_behaves_like "sends a converge message"
  end

  describe "when the run fails during cookbook synchronization" do
    let(:exception) { Exception.new("imperial to metric conversion error") }
    let(:error_description) { Chef::Formatters::ErrorMapper.cookbook_sync_failed(node, exception).for_json }
    let(:total_resource_count) { 0 }
    let(:updated_resource_count) { 0 }
    let(:status) { "failure" }
    let(:resource_record) { [] } # and no resources

    before do
      events.node_load_success(node)
      run_status.node = node
      events.run_list_expanded(expansion)
      run_status.start_clock
      expect_start_message
      events.cookbook_sync_failed(node, exception)
      run_status.stop_clock
      run_status.exception = exception
    end

    it_behaves_like "sends a converge message"
  end

  describe "after successfully starting the run" do
    before do
      # these events happen in this order in the client
      events.node_load_success(node)
      run_status.node = node
      events.run_list_expanded(expansion)
      run_status.start_clock
    end

    describe "run_start_message" do
      it "sends a run_start_message" do
        expect_start_message
        events.run_started(run_status)
      end

      it "extracts the hostname from the chef_server_url" do
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local"
        expect_start_message("chef_server_fqdn" => "spacex.rockets.local")
        events.run_started(run_status)
      end

      it "extracts the organization from the chef_server_url" do
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc"
        expect_start_message("organization_name" => "gnc")
        events.run_started(run_status)
      end

      it "extracts the organization from the chef_server_url if there are extra slashes" do
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local///organizations///gnc"
        expect_start_message("organization_name" => "gnc")
        events.run_started(run_status)
      end

      it "extracts the organization from the chef_server_url if there is a trailing slash" do
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/"
        expect_start_message("organization_name" => "gnc")
        events.run_started(run_status)
      end

      it "sets 'unknown_organization' if the cher_server_url does not contain one" do
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local"
        expect_start_message("organization_name" => "unknown_organization")
        events.run_started(run_status)
      end

      it "still uses the chef_server_url in non-solo mode even if the data_collector organization is set" do
        Chef::Config[:data_collector][:organization] = "blue-origin"
        Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/"
        expect_start_message("organization_name" => "gnc")
        events.run_started(run_status)
      end

      describe "in legacy mode" do
        before do
          Chef::Config[:solo_legacy_mode] = true
          Chef::Config[:data_collector][:server_url] = "https://nasa.rockets.local/organizations/sls"
        end

        it "we get the data collector organization" do
          Chef::Config[:data_collector][:organization] = "blue-origin"
          Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/" # should be ignored
          expect_start_message("organization_name" => "blue-origin")
          events.run_started(run_status)
        end

        it "if the data collector org is unset we get 'chef_solo'" do
          Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/" # should be ignored
          expect_start_message("organization_name" => "chef_solo")
          events.run_started(run_status)
        end

        it "sets the source" do
          expect_start_message("source" => "chef_solo")
          events.run_started(run_status)
        end
      end

      describe "in local mode" do
        before do
          Chef::Config[:local_mode] = true
          Chef::Config[:data_collector][:server_url] = "https://nasa.rockets.local/organizations/sls"
        end

        it "we get the data collector organization" do
          Chef::Config[:data_collector][:organization] = "blue-origin"
          Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/" # should be ignored
          expect_start_message("organization_name" => "blue-origin")
          events.run_started(run_status)
        end

        it "if the data collector org is unset we get 'chef_solo'" do
          Chef::Config[:chef_server_url] = "https://spacex.rockets.local/organizations/gnc/" # should be ignored
          expect_start_message("organization_name" => "chef_solo")
          events.run_started(run_status)
        end

        it "sets the source" do
          expect_start_message("source" => "chef_solo")
          events.run_started(run_status)
        end
      end
    end

    describe "converge messages" do
      before do
        expect_start_message
        events.run_started(run_status)
        events.cookbook_compilation_start(run_context)
      end

      context "with no resources" do
        let(:total_resource_count) { 0 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) { [ ] }
        let(:status) { "success" }

        before do
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"

        it "sets the policy_group" do
          node.policy_group = "acceptionsal"
          expect_converge_message("policy_group" => "acceptionsal")
          send_run_failed_or_completed_event
        end

        it "has a policy_name" do
          node.policy_name = "webappdb"
          expect_converge_message("policy_name" => "webappdb")
          send_run_failed_or_completed_event
        end

        it "collects deprecation messages" do
          location = Chef::Log.caller_location
          events.deprecation(Chef::Deprecated.create(:internal_api, "deprecation warning", location))
          expect_converge_message("deprecations" => [{ location: location, message: "deprecation warning", url: "https://docs.chef.io/deprecations_internal_api/" }])
          send_run_failed_or_completed_event
        end
      end

      context "when the run contains a file resource that is up-to-date" do
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) { [ resource_record_for(new_resource, current_resource, after_resource, :create, "up-to-date", "1234") ] }
        let(:status) { "success" }

        before do
          events.resource_action_start(new_resource, :create)
          events.resource_current_state_loaded(new_resource, :create, current_resource)
          events.resource_up_to_date(new_resource, :create)
          events.resource_after_state_loaded(new_resource, :create, after_resource)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"
      end

      context "when the run contains a file resource that is updated" do
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 1 }
        let(:resource_record) { [ resource_record_for(new_resource, current_resource, after_resource, :create, "updated", "1234") ] }
        let(:status) { "success" }

        before do
          events.resource_action_start(new_resource, :create)
          events.resource_current_state_loaded(new_resource, :create, current_resource)
          events.resource_updated(new_resource, :create)
          events.resource_after_state_loaded(new_resource, :create, after_resource)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"
      end

      context "When there is an embedded resource, it includes the sub-resource in the report" do
        let(:total_resource_count) { 2 }
        let(:updated_resource_count) { 2 }
        let(:implementation_resource) do
          r = Chef::Resource::CookbookFile.new("/preseed-file.txt")
          r.cookbook_name = cookbook_name
          r.recipe_name = recipe_name
          allow(r).to receive(:cookbook_version).and_return(cookbook_version)
          r
        end
        let(:resource_record) { [ resource_record_for(implementation_resource, implementation_resource, implementation_resource, :create, "updated", "2345"), resource_record_for(new_resource, current_resource, after_resource, :create, "updated", "1234") ] }
        let(:status) { "success" }

        before do
          events.resource_action_start(new_resource, :create)
          events.resource_current_state_loaded(new_resource, :create, current_resource)

          events.resource_action_start(implementation_resource , :create)
          events.resource_current_state_loaded(implementation_resource, :create, implementation_resource)
          events.resource_updated(implementation_resource, :create)
          events.resource_after_state_loaded(implementation_resource, :create, implementation_resource)
          implementation_resource.instance_variable_set(:@elapsed_time, 2.3456)
          events.resource_completed(implementation_resource)

          events.resource_updated(new_resource, :create)
          events.resource_after_state_loaded(new_resource, :create, after_resource)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"
      end

      context "when the run contains a file resource that is skipped due to a block conditional" do
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) do
          rec = resource_record_for(new_resource, nil, nil, :create, "skipped", "1234")
          rec["conditional"] = "not_if { #code block }" # FIXME: "#code block" is poor, is there some way to fix this?
          [ rec ]
        end
        let(:status) { "success" }

        before do
          conditional = (new_resource.not_if { true }).first
          events.resource_action_start(new_resource, :create)
          events.resource_skipped(new_resource, :create, conditional)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"
      end

      context "when the run contains a file resource that is skipped due to a string conditional" do
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) do
          rec = resource_record_for(new_resource, nil, nil, :create, "skipped", "1234")
          rec["conditional"] = 'not_if "true"'
          [ rec ]
        end
        let(:status) { "success" }

        before do
          conditional = (new_resource.not_if "true").first
          events.resource_action_start(new_resource, :create)
          events.resource_skipped(new_resource, :create, conditional)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
        end

        it_behaves_like "sends a converge message"
      end

      context "when the run contains a file resource that threw an exception" do
        let(:exception) { Exception.new("imperial to metric conversion error") }
        let(:error_description) { Chef::Formatters::ErrorMapper.resource_failed(new_resource, :create, exception).for_json }
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) do
          rec = resource_record_for(new_resource, current_resource, nil, :create, "failed", "1234")
          rec["error_message"] = "imperial to metric conversion error"
          rec["error"] = {
            "class" => exception.class,
            "message" => exception.message,
            "backtrace" => exception.backtrace,
            "description" => error_description,
          }

          [ rec ]
        end
        let(:status) { "failure" }

        before do
          exception.set_backtrace(caller)
          events.resource_action_start(new_resource, :create)
          events.resource_current_state_loaded(new_resource, :create, current_resource)
          events.resource_failed(new_resource, :create, exception)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_complete
          run_status.stop_clock
          run_status.exception = exception
        end

        it_behaves_like "sends a converge message"
      end

      context "when the run contains a file resource that threw an exception in load_current_resource" do
        let(:exception) { Exception.new("imperial to metric conversion error") }
        let(:error_description) { Chef::Formatters::ErrorMapper.resource_failed(new_resource, :create, exception).for_json }
        let(:total_resource_count) { 1 }
        let(:updated_resource_count) { 0 }
        let(:resource_record) do
          rec = resource_record_for(new_resource, nil, nil, :create, "failed", "1234")
          rec["before"] = {}
          rec["error_message"] = "imperial to metric conversion error"
          rec["error"] = {
            "class" => exception.class,
            "message" => exception.message,
            "backtrace" => exception.backtrace,
            "description" => error_description,
          }

          [ rec ]
        end
        let(:status) { "failure" }

        before do
          exception.set_backtrace(caller)
          events.resource_action_start(new_resource, :create)
          # resource_current_state_loaded is skipped
          events.resource_failed(new_resource, :create, exception)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          events.converge_failed(exception)
          run_status.stop_clock
          run_status.exception = exception
        end

        it_behaves_like "sends a converge message"
      end

      context "when the resource collection contains a resource that was unprocessed due to prior errors" do
        let(:exception) { Exception.new("imperial to metric conversion error") }
        let(:error_description) { Chef::Formatters::ErrorMapper.resource_failed(new_resource, :create, exception).for_json }
        let(:total_resource_count) { 2 }
        let(:updated_resource_count) { 0 }
        let(:unprocessed_resource) do
          res = Chef::Resource::Service.new("unprocessed service")
          res.cookbook_name = cookbook_name
          res.recipe_name = recipe_name
          allow(res).to receive(:cookbook_version).and_return(cookbook_version)
          res
        end
        let(:resource_record) do
          rec1 = resource_record_for(new_resource, current_resource, nil, :create, "failed", "1234")
          rec1["error_message"] = "imperial to metric conversion error"
          rec1["error"] = {
            "class" => exception.class,
            "message" => exception.message,
            "backtrace" => exception.backtrace,
            "description" => error_description,
          }

          rec2 = resource_record_for(unprocessed_resource, nil, nil, :nothing, "unprocessed", "")
          [ rec1, rec2 ]
        end
        let(:status) { "failure" }

        before do
          run_context.resource_collection << new_resource
          run_context.resource_collection << unprocessed_resource
          exception.set_backtrace(caller)
          events.resource_action_start(new_resource, :create)
          events.resource_current_state_loaded(new_resource, :create, current_resource)
          events.resource_failed(new_resource, :create, exception)
          new_resource.instance_variable_set(:@elapsed_time, 1.2345)
          events.resource_completed(new_resource)
          new_resource.executed_by_runner = true
          events.converge_failed(exception)
          run_status.stop_clock
          run_status.exception = exception
        end

        it_behaves_like "sends a converge message"
      end

      context "when cookbook resolution fails" do
        let(:exception) { Exception.new("imperial to metric conversion error") }
        let(:error_description) { Chef::Formatters::ErrorMapper.cookbook_resolution_failed(expansion, exception).for_json }
        let(:total_resource_count) { 0 }
        let(:updated_resource_count) { 0 }
        let(:status) { "failure" }

        before do
          events.cookbook_resolution_failed(expansion, exception)
          run_status.stop_clock
          run_status.exception = exception
        end

        it_behaves_like "sends a converge message"
      end

      context "When cookbook synchronization fails" do
        let(:exception) { Exception.new("imperial to metric conversion error") }
        let(:error_description) { Chef::Formatters::ErrorMapper.cookbook_sync_failed({}, exception).for_json }
        let(:total_resource_count) { 0 }
        let(:updated_resource_count) { 0 }
        let(:status) { "failure" }

        before do
          events.cookbook_sync_failed(expansion, exception)
          run_status.stop_clock
          run_status.exception = exception
        end

        it_behaves_like "sends a converge message"
      end

      context "when node attributes are block-listed" do
        let(:status) { "success" }
        before do
          Chef::Config[:blocked_default_attributes] = [
            %w{secret key_to_the_kingdom},
          ]
          node.default = {
            "secret" => { "key_to_the_kingdom" => "under the flower pot to the left of the drawbridge" },
            "publicinfo" => { "num_flower_pots" => 18 },
          }
        end

        it "payload should exclude blocked attributes" do
          expect(rest_client).to receive(:post) do |_addr, hash, _headers|
            expect(hash["node"]["default"]).to eq({ "secret" => {}, "publicinfo" => { "num_flower_pots" => 18 } })
          end
          send_run_failed_or_completed_event
        end
      end

      context "when node attributes are allow-listed" do
        let(:status) { "success" }
        before do
          Chef::Config[:allowed_default_attributes] = [
            %w{public entrance},
          ]
          node.default = {
            "public" => { "entrance" => "is the drawbridge" },
            "secret" => { "entrance" => "is the tunnel" },
          }
        end

        it "payload should include only allowed attributes" do
          expect(rest_client).to receive(:post) do |_addr, hash, _headers|
            expect(hash["node"]["default"]).to eq({ "public" => { "entrance" => "is the drawbridge" } })
          end
          send_run_failed_or_completed_event
        end
      end

    end
  end

  describe "#send_to_file_location(file_name, message)" do
    let(:tempfile) { Tempfile.new("rspec-chef-datacollector-out") }
    let(:shift_jis) { "I have no idea what this character is:\n #{0x83.chr}#{0x80.chr}.\n" }
    it "handles invalid UTF-8 properly" do
      data_collector.send(:send_to_file_location, tempfile, { invalid: shift_jis })
    end
  end

  describe "#send_to_datacollector" do
    def stub_http_client(exception = nil)
      if exception.nil?
        expect(http_client).to receive(:post).with(nil, message, data_collector.send(:headers))
      else
        expect(http_client).to receive(:post).with(nil, message, data_collector.send(:headers)).and_raise(exception)
      end
    end

    let(:message) { "message" }
    let(:http_client) { instance_double(Chef::ServerAPI) }

    before do
      expect(data_collector).to receive(:setup_http_client).and_return(http_client)
    end

    it "does not disable the data_collector when no exception is raised" do
      stub_http_client
      expect(data_collector.events).not_to receive(:unregister)
      data_collector.send(:send_to_data_collector, message)
    end

    errors = [ Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
               Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
               Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError,
               Errno::EHOSTDOWN ]

    errors.each do |exception_class|
      context "when the client raises a #{exception_class} exception" do
        before do
          stub_http_client(exception_class)
        end

        it "disables the reporter" do
          expect(data_collector.events).to receive(:unregister).with(data_collector)
          data_collector.send(:send_to_data_collector, message)
        end

        it "logs an error and raises when raise_on_failure is enabled" do
          Chef::Config[:data_collector][:raise_on_failure] = true
          expect(Chef::Log).to receive(:error)
          expect { data_collector.send(:send_to_data_collector, message) }.to raise_error(exception_class)
        end

        it "logs a warn message and does not raise an exception when raise_on_failure is disabled" do
          Chef::Config[:data_collector][:raise_on_failure] = false
          expect(Chef::Log).to receive(:warn)
          data_collector.send(:send_to_data_collector, message)
        end
      end
    end

    context "when the client raises a 404 exception" do
      let(:err) do
        response = double("Net::HTTP response", code: "404")
        Net::HTTPClientException.new("Not Found", response)
      end

      before do
        stub_http_client(err)
      end

      it "disables the reporter" do
        expect(data_collector.events).to receive(:unregister).with(data_collector)
        data_collector.send(:send_to_data_collector, message)
      end

      it "logs an error and raises when raise_on_failure is enabled" do
        Chef::Config[:data_collector][:raise_on_failure] = true
        expect(Chef::Log).to receive(:error)
        expect { data_collector.send(:send_to_data_collector, message) }.to raise_error(err)
      end

      # this is different specifically for 404s
      it "logs an info message and does not raise an exception when raise_on_failure is disabled" do
        Chef::Config[:data_collector][:raise_on_failure] = false
        expect(Chef::Log).to receive(:debug).with(/This is normal if you do not have Chef Automate/)
        data_collector.send(:send_to_data_collector, message)
      end
    end
  end
end
