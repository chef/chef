#
# Author:: Stephen Delano (<stephen@chef.io>)
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

require "knife_spec_helper"

describe Chef::Knife::ClientBulkDelete do
  let(:stdout_io) { StringIO.new }
  let(:stdout) { stdout_io.string }
  let(:stderr_io) { StringIO.new }
  let(:stderr) { stderr_io.string }

  let(:knife) do
    k = Chef::Knife::ClientBulkDelete.new
    k.name_args = name_args
    k.config = option_args
    allow(k.ui).to receive(:stdout).and_return(stdout_io)
    allow(k.ui).to receive(:stderr).and_return(stderr_io)
    allow(k.ui).to receive(:confirm).and_return(knife_confirm)
    allow(k.ui).to receive(:confirm_without_exit).and_return(knife_confirm)
    k
  end

  let(:name_args) { [ "." ] }
  let(:option_args) { {} }

  let(:knife_confirm) { true }

  let(:nonvalidator_client_names) { %w{tim dan stephen} }
  let(:nonvalidator_clients) do
    clients = {}

    nonvalidator_client_names.each do |client_name|
      client = Chef::ApiClientV1.new
      client.name(client_name)
      allow(client).to receive(:destroy).and_return(true)
      clients[client_name] = client
    end

    clients
  end

  let(:validator_client_names) { %w{myorg-validator} }
  let(:validator_clients) do
    clients = {}

    validator_client_names.each do |validator_client_name|
      validator_client = Chef::ApiClientV1.new
      validator_client.name(validator_client_name)
      allow(validator_client).to receive(:validator).and_return(true)
      allow(validator_client).to receive(:destroy).and_return(true)
      clients[validator_client_name] = validator_client
    end

    clients
  end

  let(:client_names) { nonvalidator_client_names + validator_client_names }
  let(:clients) do
    nonvalidator_clients.merge(validator_clients)
  end

  before(:each) do
    allow(Chef::ApiClientV1).to receive(:list).and_return(clients)
  end

  describe "run" do
    describe "without a regex" do
      let(:name_args) { [ ] }

      it "should exit if the regex is not provided" do
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    describe "with any clients" do
      it "should get the list of the clients" do
        expect(Chef::ApiClientV1).to receive(:list)
        knife.run
      end

      it "should print the name of the clients" do
        knife.run
        client_names.each do |client_name|
          expect(stdout).to include(client_name)
        end
      end

      it "should confirm you really want to delete them" do
        expect(knife.ui).to receive(:confirm)
        knife.run
      end

      describe "without --delete-validators" do
        it "should mention that validator clients wont be deleted" do
          knife.run
          expect(stdout).to include("The following clients are validators and will not be deleted:")
          info = stdout.index "The following clients are validators and will not be deleted:"
          val = stdout.index "myorg-validator"
          expect(val > info).to be_truthy
        end

        it "should only delete nonvalidator clients" do
          nonvalidator_clients.each_value do |c|
            expect(c).to receive(:destroy)
          end

          validator_clients.each_value do |c|
            expect(c).not_to receive(:destroy)
          end

          knife.run
        end
      end

      describe "with --delete-validators" do
        let(:option_args) { { delete_validators: true } }

        it "should mention that validator clients will be deleted" do
          knife.run
          expect(stdout).to include("The following validators will be deleted")
        end

        it "should confirm twice" do
          expect(knife.ui).to receive(:confirm).once
          expect(knife.ui).to receive(:confirm_without_exit).once
          knife.run
        end

        it "should delete all clients" do
          clients.each_value do |c|
            expect(c).to receive(:destroy)
          end

          knife.run
        end
      end
    end

    describe "with some clients" do
      let(:name_args) { [ "^ti" ] }

      it "should only delete clients that match the regex" do
        expect(clients["tim"]).to receive(:destroy)
        expect(clients["stephen"]).not_to receive(:destroy)
        expect(clients["dan"]).not_to receive(:destroy)
        expect(clients["myorg-validator"]).not_to receive(:destroy)
        knife.run
      end
    end
  end
end
