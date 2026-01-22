#
# Author:: Ashique Saidalavi (<ashique.saidalavi@progress.com>)
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

require "knife_spec_helper"

describe Chef::Knife::Search do
  describe "node" do
    let(:knife) { Chef::Knife::Search.new }
    let(:query) { double("Chef::Search::Query") }
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }

    before(:each) do
      node = Chef::Node.new.tap do |n|
        n.automatic_attrs["fqdn"] = "foobar"
        n.automatic_attrs["ohai_time"] = 1343845969
        n.automatic_attrs["platform"] = "mac_os_x"
        n.automatic_attrs["platform_version"] = "10.12.5"
      end

      allow(query).to receive(:search).and_yield(node)
      allow(Chef::Search::Query).to receive(:new).and_return(query)

      allow(knife).to receive(:output).and_return(true)
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      allow(knife.ui).to receive(:stderr).and_return(stderr)
    end

    describe "run" do
      it "should be successful" do
        knife.name_args = ["node", ":"]
        expect(query).to receive(:search).with("node", ":", { fuzz: true })
        knife.run
      end

      context "read_cli_args" do
        it "should be invoked" do
          expect(knife).to receive(:read_cli_args)
          knife.run
        end

        it "should raise error if query passed with argument as well as -q option" do
          knife.name_args = ["node", ":"]
          knife.config[:query] = ":"

          expect { knife.run }.to raise_error(SystemExit)
          expect(stderr.string).to match /Please specify query as an argument or an option via -q, not both/im
        end

        it "should fail if no query passed" do
          knife.name_args = []

          expect { knife.run }.to raise_error(SystemExit)
          expect(stderr.string).to match /No query specified/im
        end
      end

      context "filters" do
        before do
          knife.name_args = ["node", "packages:git"]
          knife.config[:filter_result] = "env=chef_environment"
        end

        it "should invoke create_result_filter" do
          expect(knife).to receive(:create_result_filter).with("env=chef_environment")
          knife.run
        end

        it "should invoke search object with correct filter" do
          expect(query).to receive(:search).with("node", "packages:git", { filter_result: { env: ["chef_environment"] }, fuzz: true })
          knife.run
        end
      end

      context "attributes" do
        before do
          knife.name_args = ["node", "packages:git"]
          knife.ui.config[:attribute] = ["packages.git.version"]
        end

        it "should invoke create_result_filter_from_attributes method" do
          expect(knife).to receive(:create_result_filter_from_attributes).with(["packages.git.version"], knife.ui.attribute_field_separator)
          knife.run
        end

        it "should invoke search query with correct filter" do
          filter_obj = {
            filter_result: {
              "__display_name" => ["name"],
              "packages.git.version" => %w{packages git version} },
            fuzz: true,
          }
          expect(query).to receive(:search).with("node", "packages:git", filter_obj)
          knife.run
        end

        context "field_separator" do
          it "should have dot as the default field_separator" do
            expect(knife.ui.attribute_field_separator).to eq(".")
          end

          it "has the correct field_separator" do
            knife.config[:field_separator] = ":"

            expect(knife.ui.attribute_field_separator).to eq(":")
          end

          context "parsing" do
            before do
              knife.name_args = %w{node packages:git}
            end

            it "parses the attributes correctly for dot field_separator" do
              knife.config[:field_separator] = "."
              knife.ui.config[:attribute] = ["packages.git.version"]

              filter_output = { "__display_name" => ["name"], "packages.git.version" => %w{packages git version} }
              expect(knife.create_result_filter_from_attributes(["packages.git.version"], ".")).to eq(filter_output)
            end

            it "parses it for different field_separator" do
              knife.config[:field_separator] = ":"
              knife.ui.config[:attribute] = ["packages:git:version"]

              filter_output = { "__display_name" => ["name"], "packages:git:version" => %w{packages git version} }
              expect(knife.create_result_filter_from_attributes(["packages:git:version"], ":")).to eq(filter_output)
            end
          end
        end
      end
    end
  end
end
