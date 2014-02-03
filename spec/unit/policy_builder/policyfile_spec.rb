#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright 2014 Chef Software, Inc.
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

require 'spec_helper'
require 'chef/policy_builder'

describe Chef::PolicyBuilder::Policyfile do

  let(:node_name) { "joe_node" }
  let(:ohai_data) { {"platform" => "ubuntu", "platform_version" => "13.04", "fqdn" => "joenode.example.com"} }
  let(:json_attribs) { {"custom_attr" => "custom_attr_value"} }
  let(:override_runlist) { nil }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:policy_builder) { Chef::PolicyBuilder::Policyfile.new(node_name, ohai_data, json_attribs, override_runlist, events) }

  # Convert a SHA1 (160 bit) hex string into an x.y.z version number where the
  # maximum value is smaller than a postgres BIGINT (signed 64bit, so 63 usable
  # bits). This requires enterprise Chef or open source server 11.1.0+ (currently not released)
  #
  # The SHA1 is devided as follows:
  # * "major": first 14 chars (56 bits)
  # * "minor": next 14 chars (56 bits)
  # * "patch": last 12 chars (48 bits)
  def id_to_dotted(sha1_id)
    major = sha1_id[0...14]
    minor = sha1_id[14...28]
    patch = sha1_id[28..40]
    decimal_integers =[major, minor, patch].map {|hex| hex.to_i(16) }
    decimal_integers.join(".")
  end


  let(:example1_lock_data) do
    # based on https://github.com/danielsdeleo/chef-workflow2-prototype/blob/master/skeletons/basic_policy/Policyfile.lock.json
    {
      "identifier" => "168d2102fb11c9617cd8a981166c8adc30a6e915",
      "version" => "2.3.5",
      # NOTE: for compatibility mode we include the dotted id in the policyfile to enhance discoverability.
      "dotted_decimal_identifier" => id_to_dotted("168d2102fb11c9617cd8a981166c8adc30a6e915"),
      "source" => { "path" => "./cookbooks/demo" },
      "scm_identifier"=> {
        "vcs"=> "git",
        "rev_id"=> "9d5b09026470c322c3cb5ca8a4157c4d2f16cef3",
        "remote"=> nil
      }
    }
  end

  let(:example2_lock_data) do
    {
      "identifier" => "feab40e1fca77c7360ccca1481bb8ba5f919ce3a",
      "version" => "4.2.0",
      # NOTE: for compatibility mode we include the dotted id in the policyfile to enhance discoverability.
      "dotted_decimal_identifier" => id_to_dotted("feab40e1fca77c7360ccca1481bb8ba5f919ce3a"),
      "source" => { "api" => "https://community.getchef.com/api/v1/cookbooks/example2" }
    }
  end

  let(:policyfile_default_attributes) { {"policyfile_default_attr" => "policyfile_default_value"} }
  let(:policyfile_override_attributes) { {"policyfile_override_attr" => "policyfile_override_value"} }

  let(:policyfile_run_list) { ["recipe[example1::default]", "recipe[example2::server]"] }

  let(:parsed_policyfile_json) do
    {
      "run_list" => policyfile_run_list,

      "cookbook_locks" => {
        "example1" => example1_lock_data,
        "example2" => example2_lock_data
      },

      "default_attributes" => policyfile_default_attributes,
      "override_attributes" => policyfile_override_attributes
    }
  end

  let(:err_namespace) { Chef::PolicyBuilder::Policyfile }

  it "configures a Chef HTTP API client" do
    http = double("Chef::REST")
    server_url = "https://api.opscode.com/organizations/example"
    Chef::Config[:chef_server_url] = server_url
    Chef::REST.should_receive(:new).with(server_url).and_return(http)
    expect(policy_builder.http_api).to eq(http)
  end

  describe "reporting unsupported features" do

    def initialize_pb
      Chef::PolicyBuilder::Policyfile.new(node_name, ohai_data, json_attribs, override_runlist, events)
    end

    it "always gives `false` for #temporary_policy?" do
      expect(initialize_pb.temporary_policy?).to be_false
    end

    context "chef-solo" do
      before { Chef::Config[:solo] = true }

      it "errors on create" do
        expect { initialize_pb }.to raise_error(err_namespace::UnsupportedFeature)
      end
    end

    context "when given an override run_list" do
      let(:override_runlist) { "recipe[foo],recipe[bar]" }

      it "errors on create" do
        expect { initialize_pb }.to raise_error(err_namespace::UnsupportedFeature)
      end
    end

    context "when json_attribs contains a run_list" do
      let(:json_attribs) { {"run_list" => []} }

      it "errors on create" do
        expect { initialize_pb }.to raise_error(err_namespace::UnsupportedFeature)
      end
    end

    context "when an environment is configured" do
      before { Chef::Config[:environment] = "blurch" }

      it "errors when an environment is configured" do
        expect { initialize_pb }.to raise_error(err_namespace::UnsupportedFeature)
      end
    end

  end

  describe "when using compatibility mode" do

    let(:http_api) { double("Chef::REST") }

    let(:configured_environment) { nil }

    let(:override_runlist) { nil }
    let(:primary_runlist) { nil }

    let(:original_default_attrs) { {"default_key" => "default_value"} }
    let(:original_override_attrs) { {"override_key" => "override_value"} }

    let(:node) do
      node = Chef::Node.new
      node.name(node_name)
      node.default_attrs = original_default_attrs
      node.override_attrs = original_override_attrs
      node.run_list(primary_runlist) if primary_runlist
      node
    end

    before do
      # TODO: agree on this name and logic.
      Chef::Config[:deployment_group] = "example-policy-stage"
      policy_builder.stub(:http_api).and_return(http_api)
    end

    context "when the deployment group cannot be loaded" do
      let(:error404) { Net::HTTPServerException.new("404 message", :body) }

      before do
        Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)
        http_api.should_receive(:get).
          with("data/policyfiles/example-policy-stage").
          and_raise(error404)
      end

      it "raises an error" do
        expect { policy_builder.load_node }.to raise_error(err_namespace::ConfigurationError)
      end

      it "sends error message to the event system" do
        events.should_receive(:node_load_failed).with(node_name, an_instance_of(err_namespace::ConfigurationError), Chef::Config)
        expect { policy_builder.load_node }.to raise_error(err_namespace::ConfigurationError)
      end

    end

    describe "when the deployment_group is not configured" do
      before do
        Chef::Config[:deployment_group] = nil
        Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)
      end

      it "errors while loading the node" do
        expect { policy_builder.load_node }.to raise_error(err_namespace::ConfigurationError)
      end


      it "passes error information to the event system" do
        # TODO: also make sure something acceptable happens with the error formatters
        err_class = err_namespace::ConfigurationError
        events.should_receive(:node_load_failed).with(node_name, an_instance_of(err_class), Chef::Config)
        expect { policy_builder.load_node }.to raise_error(err_class)
      end
    end

    context "and a deployment_group is configured" do
      before do
        http_api.should_receive(:get).with("data/policyfiles/example-policy-stage").and_return(parsed_policyfile_json)
      end

      it "fetches the policy file from a data bag item" do
        expect(policy_builder.policy).to eq(parsed_policyfile_json)
      end

      it "extracts the run_list from the policyfile" do
        expect(policy_builder.run_list).to eq(policyfile_run_list)
      end

      it "extracts the cookbooks and versions for display from the policyfile" do
        expected = [
          "example1::default@2.3.5 (168d210)",
          "example2::server@4.2.0 (feab40e)"
        ]

        expect(policy_builder.run_list_with_versions_for_display).to eq(expected)
      end

      it "generates a RunListExpansion-alike object for feeding to the CookbookCompiler" do
        expect(policy_builder.run_list_expansion_ish).to respond_to(:recipes)
        expect(policy_builder.run_list_expansion_ish.recipes).to eq(["example1::default", "example2::server"])
      end

      it "implements #expand_run_list in a manner compatible with ExpandNodeObject" do
        Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)
        policy_builder.load_node
        expect(policy_builder.expand_run_list).to respond_to(:recipes)
        expect(policy_builder.expand_run_list.recipes).to eq(["example1::default", "example2::server"])
        expect(policy_builder.expand_run_list.roles).to eq([])
      end


      describe "validating the Policyfile.lock" do

        it "errors if the policyfile json contains any non-recipe items" do
          parsed_policyfile_json["run_list"] = ["role[foo]"]
          expect { policy_builder.validate_policyfile }.to raise_error(err_namespace::PolicyfileError)
        end

        it "errors if the policyfile json contains non-fully qualified recipe items" do
          parsed_policyfile_json["run_list"] = ["recipe[foo]"]
          expect { policy_builder.validate_policyfile }.to raise_error(err_namespace::PolicyfileError)
        end

        it "errors if the policyfile doesn't have a run_list key" do
          parsed_policyfile_json.delete("run_list")
          expect { policy_builder.validate_policyfile }.to raise_error(err_namespace::PolicyfileError)
        end

        it "error if the policyfile doesn't have a cookbook_locks key" do
          parsed_policyfile_json.delete("cookbook_locks")
          expect { policy_builder.validate_policyfile }.to raise_error(err_namespace::PolicyfileError)
        end

        it "accepts a valid policyfile" do
          policy_builder.validate_policyfile
        end

      end

      describe "building the node object" do

        before do
          Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)

          policy_builder.load_node
          policy_builder.build_node
        end

        it "resets default and override data" do
          expect(node["default_key"]).to be_nil
          expect(node["override_key"]).to be_nil
        end

        it "applies ohai data" do
          expect(ohai_data).to_not be_empty # ensure test is testing something
          ohai_data.each do |key, value|
            expect(node.automatic_attrs[key]).to eq(value)
          end
        end

        it "applies attributes from json file" do
          expect(node["custom_attr"]).to eq("custom_attr_value")
        end

        it "applies attributes from the policyfile" do
          expect(node["policyfile_default_attr"]).to eq("policyfile_default_value")
          expect(node["policyfile_override_attr"]).to eq("policyfile_override_value")
        end

        it "sets the policyfile's run_list on the node object" do
          expect(node.run_list).to eq(policyfile_run_list)
        end

        it "creates node.automatic_attrs[:roles]" do
          expect(node.automatic_attrs[:roles]).to eq([])
        end

        it "create node.automatic_attrs[:recipes]" do
          expect(node.automatic_attrs[:recipes]).to eq(["example1::default", "example2::server"])
        end

      end


      describe "fetching the desired cookbook set" do

        let(:example1_cookbook_object) { double("Chef::CookbookVersion for example1 cookbook") }
        let(:example2_cookbook_object) { double("Chef::CookbookVersion for example2 cookbook") }

        let(:expected_cookbook_hash) do
          { "example1" => example1_cookbook_object, "example2" => example2_cookbook_object }
        end

        let(:example1_xyz_version) { example1_lock_data["dotted_decimal_identifier"] }
        let(:example2_xyz_version) { example2_lock_data["dotted_decimal_identifier"] }

        let(:cookbook_synchronizer) { double("Chef::CookbookSynchronizer") }

        context "and a cookbook is missing" do

          let(:error404) { Net::HTTPServerException.new("404 message", :body) }

          before do
            Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)

            # Remove references to example2 cookbook because we're iterating
            # over a Hash data structure and on ruby 1.8.7 iteration order will
            # not be stable.
            parsed_policyfile_json["cookbook_locks"].delete("example2")
            parsed_policyfile_json["run_list"].delete("recipe[example2::server]")

            policy_builder.load_node
            policy_builder.build_node

            http_api.should_receive(:get).with("cookbooks/example1/#{example1_xyz_version}").
              and_raise(error404)
          end

          it "raises an error indicating which cookbook is missing" do
            expect { policy_builder.cookbooks_to_sync }.to raise_error(Chef::Exceptions::CookbookNotFound)
          end

        end

        context "and the cookbooks can be fetched" do
          before do
            Chef::Node.should_receive(:find_or_create).with(node_name).and_return(node)

            policy_builder.load_node
            policy_builder.build_node

            http_api.should_receive(:get).with("cookbooks/example1/#{example1_xyz_version}").
              and_return(example1_cookbook_object)
            http_api.should_receive(:get).with("cookbooks/example2/#{example2_xyz_version}").
              and_return(example2_cookbook_object)

            Chef::CookbookSynchronizer.stub(:new).
              with(expected_cookbook_hash, events).
              and_return(cookbook_synchronizer)
          end

          it "builds a Hash of the form 'cookbook_name' => Chef::CookbookVersion" do
            expect(policy_builder.cookbooks_to_sync).to eq(expected_cookbook_hash)
          end

          it "syncs the desired cookbooks via CookbookSynchronizer" do
            cookbook_synchronizer.should_receive(:sync_cookbooks)
            policy_builder.sync_cookbooks
          end

          it "builds a run context" do
            cookbook_synchronizer.should_receive(:sync_cookbooks)
            Chef::RunContext.any_instance.should_receive(:load).with(policy_builder.run_list_expansion_ish)
            run_context = policy_builder.setup_run_context
            expect(run_context.node).to eq(node)
            expect(run_context.cookbook_collection.keys).to match_array(["example1", "example2"])
          end

        end
      end
    end

  end

end
