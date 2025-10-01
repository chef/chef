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
require "chef/knife/user_key_edit"
require "chef/knife/client_key_edit"
require "chef/knife/key_edit"
require "chef/key"

describe "key edit commands that inherit knife" do
  shared_examples_for "a key edit command" do
    let(:stderr) { StringIO.new }
    let(:params) { [] }
    let(:service_object) { instance_double(Chef::Knife::KeyEdit) }
    let(:command) do
      c = described_class.new([])
      c.ui.config[:disable_editing] = true
      allow(c.ui).to receive(:stderr).and_return(stderr)
      allow(c.ui).to receive(:stdout).and_return(stderr)
      allow(c).to receive(:show_usage)
      c
    end

    context "after apply_params! is called with valid args" do
      let(:params) { %w{charmander charmander-key} }
      before do
        command.apply_params!(params)
      end

      context "when the service object is called" do
        it "creates a new instance of Chef::Knife::KeyEdit with the correct args" do
          expect(Chef::Knife::KeyEdit).to receive(:new)
            .with("charmander-key", "charmander", command.actor_field_name, command.ui, command.config)
            .and_return(service_object)
          command.service_object
        end
      end # when the service object is called
    end # after apply_params! is called with valid args
  end # a key edit command

  describe Chef::Knife::UserKeyEdit do
    it_should_behave_like "a key edit command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyEdit) }
      let(:params) { %w{charmander charmander-key} }
    end
  end

  describe Chef::Knife::ClientKeyEdit do
    it_should_behave_like "a key edit command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyEdit) }
      let(:params) { %w{charmander charmander-key} }
    end
  end
end

describe Chef::Knife::KeyEdit do
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
  let(:keyname) { "charmander-key" }
  let(:ui) { instance_double("Chef::Knife::UI") }

  shared_examples_for "key edit run command" do
    let(:key_edit_object) do
      described_class.new(keyname, actor, actor_field_name, ui, config)
    end

    context "when the command is run" do
      let(:expected_hash) do
        {
          actor_field_name => "charmander",
        }
      end
      let(:new_keyname) { "charizard-key" }

      before do
        allow(File).to receive(:read).and_return(public_key)
        allow(File).to receive(:expand_path)

        allow(key_edit_object).to receive(:output_private_key_to_file)
        allow(key_edit_object).to receive(:display_private_key)
        allow(key_edit_object).to receive(:edit_hash).and_return(expected_hash)
        allow(key_edit_object).to receive(:display_info)
      end

      context "when public_key and create_key are passed" do
        before do
          key_edit_object.config[:public_key] = "public_key_path"
          key_edit_object.config[:create_key] = true
        end

        it "raises a Chef::Exceptions::KeyCommandInputError with the proper error message" do
          expect { key_edit_object.run }.to raise_error(Chef::Exceptions::KeyCommandInputError, key_edit_object.public_key_and_create_key_error_msg)
        end
      end

      context "when key_name is passed" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "name" => new_keyname,
          }
        end
        before do
          key_edit_object.config[:key_name] = new_keyname
          allow_any_instance_of(Chef::Key).to receive(:update)
        end

        it "update_key_from_hash gets passed a hash with new key name" do
          expect(key_edit_object).to receive(:update_key_from_hash).with(expected_hash).and_return(Chef::Key.from_hash(expected_hash))
          key_edit_object.run
        end

        it "Chef::Key.update is passed a string containing the original keyname" do
          expect_any_instance_of(Chef::Key).to receive(:update).with(/#{keyname}/).and_return(Chef::Key.from_hash(expected_hash))
          key_edit_object.run
        end

        it "Chef::Key.update is not passed a string containing the new keyname" do
          expect_any_instance_of(Chef::Key).not_to receive(:update).with(/#{new_keyname}/)
          allow_any_instance_of(Chef::Key).to receive(:update).and_return(Chef::Key.from_hash(expected_hash))
          key_edit_object.run
        end
      end

      context "when public_key, key_name, and expiration_date are passed" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "public_key" => public_key,
            "name" => new_keyname,
            "expiration_date" => "infinity",
          }
        end
        before do
          key_edit_object.config[:public_key] = "this-public-key"
          key_edit_object.config[:key_name] = new_keyname
          key_edit_object.config[:expiration_date] = "infinity"
          allow(key_edit_object).to receive(:update_key_from_hash).and_return(Chef::Key.from_hash(expected_hash))
        end

        it "passes the right hash to update_key_from_hash" do
          expect(key_edit_object).to receive(:update_key_from_hash).with(expected_hash)
          key_edit_object.run
        end
      end

      context "when create_key is passed" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "create_key" => true,
          }
        end

        before do
          key_edit_object.config[:create_key] = true
          allow(key_edit_object).to receive(:update_key_from_hash).and_return(Chef::Key.from_hash(expected_hash))
        end

        it "passes the right hash to update_key_from_hash" do
          expect(key_edit_object).to receive(:update_key_from_hash).with(expected_hash)
          key_edit_object.run
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
          allow(key_edit_object).to receive(:update_key_from_hash).and_return(Chef::Key.from_hash(expected_hash))
          key_edit_object.config[:public_key] = "public_key_path"
        end

        it "calls File.expand_path with the public_key input" do
          expect(File).to receive(:expand_path).with("public_key_path")
          key_edit_object.run
        end
      end # when public_key is passed

      context "when the server returns a private key" do
        let(:expected_hash) do
          {
            actor_field_name => "charmander",
            "public_key" => public_key,
            "private_key" => "super_private",
          }
        end

        before do
          allow(key_edit_object).to receive(:update_key_from_hash).and_return(Chef::Key.from_hash(expected_hash))
          key_edit_object.config[:public_key] = "public_key_path"
        end

        context "when file is not passed" do
          it "calls display_private_key with the private_key" do
            expect(key_edit_object).to receive(:display_private_key).with("super_private")
            key_edit_object.run
          end
        end

        context "when file is passed" do
          before do
            key_edit_object.config[:file] = "/fake/file"
          end

          it "calls output_private_key_to_file with the private_key" do
            expect(key_edit_object).to receive(:output_private_key_to_file).with("super_private")
            key_edit_object.run
          end
        end
      end # when the server returns a private key

    end # when the command is run

  end # key edit run command

  context "when actor_field_name is 'user'" do
    it_should_behave_like "key edit run command" do
      let(:actor_field_name) { "user" }
    end
  end

  context "when actor_field_name is 'client'" do
    it_should_behave_like "key edit run command" do
      let(:actor_field_name) { "client" }
    end
  end
end
