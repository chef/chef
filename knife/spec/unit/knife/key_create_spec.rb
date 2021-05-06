#
# Author:: Tyler Cloke (<tyler@chef.io>)
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
require "chef/knife/user_key_create"
require "chef/knife/client_key_create"
require "chef/knife/key_create"
require "chef/key"

describe "key create commands that inherit knife" do
  shared_examples_for "a key create command" do
    let(:stderr) { StringIO.new }
    let(:params) { [] }
    let(:service_object) { instance_double(Chef::Knife::KeyCreate) }
    let(:command) do
      c = described_class.new([])
      c.ui.config[:disable_editing] = true
      allow(c.ui).to receive(:stderr).and_return(stderr)
      allow(c.ui).to receive(:stdout).and_return(stderr)
      allow(c).to receive(:show_usage)
      c
    end

    context "after apply_params! is called with valid args" do
      let(:params) { ["charmander"] }
      before do
        command.apply_params!(params)
      end

      context "when the service object is called" do
        it "creates a new instance of Chef::Knife::KeyCreate with the correct args" do
          expect(Chef::Knife::KeyCreate).to receive(:new)
            .with("charmander", command.actor_field_name, command.ui, command.config)
            .and_return(service_object)
          command.service_object
        end
      end # when the service object is called
    end # after apply_params! is called with valid args
  end # a key create command

  describe Chef::Knife::UserKeyCreate do
    it_should_behave_like "a key create command"
    # defined in key_helper.rb
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyCreate) }
      let(:params) { ["charmander"] }
    end
  end

  describe Chef::Knife::ClientKeyCreate do
    it_should_behave_like "a key create command"
    # defined in key_helper.rb
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyCreate) }
      let(:params) { ["charmander"] }
    end
  end
end

describe Chef::Knife::KeyCreate do
  let(:public_key) do
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvPo+oNPB7uuNkws0fC02
KxSwdyqPLu0fhI1pOweNKAZeEIiEz2PkybathHWy8snSXGNxsITkf3eyvIIKa8OZ
WrlqpI3yv/5DOP8HTMCxnFuMJQtDwMcevlqebX4bCxcByuBpNYDcAHjjfLGSfMjn
E5lZpgYWwnpic4kSjYcL9ORK9nYvlWV9P/kCYmRhIjB4AhtpWRiOfY/TKi3P2LxT
IjSmiN/ihHtlhV/VSnBJ5PzT/lRknlrJ4kACoz7Pq9jv+aAx5ft/xE9yDa2DYs0q
Tfuc9dUYsFjptWYrV6pfEQ+bgo1OGBXORBFcFL+2D7u9JYquKrMgosznHoEkQNLo
0wIDAQAB
-----END PUBLIC KEY-----"
  end
  let(:config) { {} }
  let(:actor) { "charmander" }
  let(:ui) { instance_double("Chef::Knife::UI") }

  shared_examples_for "key create run command" do
    let(:key_create_object) do
      described_class.new(actor, actor_field_name, ui, config)
    end

    context "when public_key and key_name weren't passed" do
      it "raises a Chef::Exceptions::KeyCommandInputError with the proper error message" do
        expect { key_create_object.run }.to raise_error(Chef::Exceptions::KeyCommandInputError, key_create_object.public_key_or_key_name_error_msg)
      end
    end

    context "when the command is run" do
      let(:expected_hash) do
        {
          actor_field_name => "charmander",
        }
      end

      before do
        allow(File).to receive(:read).and_return(public_key)
        allow(File).to receive(:expand_path)

        allow(key_create_object).to receive(:output_private_key_to_file)
        allow(key_create_object).to receive(:display_private_key)
        allow(key_create_object).to receive(:edit_hash).and_return(expected_hash)
        allow(key_create_object).to receive(:create_key_from_hash).and_return(Chef::Key.from_hash(expected_hash))
        allow(key_create_object).to receive(:display_info)
      end

      context "when a valid hash is passed" do
        let(:key_name) { "charmander-key" }
        let(:valid_expiration_date) { "2020-12-24T21:00:00Z" }
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "public_key" => public_key,
            "expiration_date" => valid_expiration_date,
            "key_name" => key_name,
          }
        end
        before do
          key_create_object.config[:public_key] = "public_key_path"
          key_create_object.config[:expiration_Date] = valid_expiration_date,
          key_create_object.config[:key_name] = key_name
        end

        it "creates the proper hash" do
          expect(key_create_object).to receive(:create_key_from_hash).with(expected_hash)
          key_create_object.run
        end
      end

      context "when public_key is passed" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "public_key" => public_key,
          }
        end
        before do
          key_create_object.config[:public_key] = "public_key_path"
        end

        it "calls File.expand_path with the public_key input" do
          expect(File).to receive(:expand_path).with("public_key_path")
          key_create_object.run
        end
      end # when public_key is passed

      context "when public_key isn't passed and key_name is" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "name" => "charmander-key",
            "create_key" => true,
          }
        end
        before do
          key_create_object.config[:key_name] = "charmander-key"
        end

        it "should set create_key to true" do
          expect(key_create_object).to receive(:create_key_from_hash).with(expected_hash)
          key_create_object.run
        end
      end

      context "when the server returns a private key" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "public_key" => public_key,
            "private_key" => "super_private",
          }
        end

        before do
          key_create_object.config[:public_key] = "public_key_path"
        end

        context "when file is not passed" do
          it "calls display_private_key with the private_key" do
            expect(key_create_object).to receive(:display_private_key).with("super_private")
            key_create_object.run
          end
        end

        context "when file is passed" do
          before do
            key_create_object.config[:file] = "/fake/file"
          end

          it "calls output_private_key_to_file with the private_key" do
            expect(key_create_object).to receive(:output_private_key_to_file).with("super_private")
            key_create_object.run
          end
        end
      end # when the server returns a private key
    end # when the command is run
  end # key create run command"

  context "when actor_field_name is 'user'" do
    it_should_behave_like "key create run command" do
      let(:actor_field_name) { "user" }
    end
  end

  context "when actor_field_name is 'client'" do
    it_should_behave_like "key create run command" do
      let(:actor_field_name) { "client" }
    end
  end
end
