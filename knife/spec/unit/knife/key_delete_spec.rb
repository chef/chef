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
require "chef/knife/user_key_delete"
require "chef/knife/client_key_delete"
require "chef/knife/key_delete"
require "chef/key"

describe "key delete commands that inherit knife" do
  shared_examples_for "a key delete command" do
    let(:stderr) { StringIO.new }
    let(:params) { [] }
    let(:service_object) { instance_double(Chef::Knife::KeyDelete) }
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
        it "creates a new instance of Chef::Knife::KeyDelete with the correct args" do
          expect(Chef::Knife::KeyDelete).to receive(:new)
            .with("charmander-key", "charmander", command.actor_field_name, command.ui)
            .and_return(service_object)
          command.service_object
        end
      end # when the service object is called
    end # after apply_params! is called with valid args
  end # a key delete command

  describe Chef::Knife::UserKeyDelete do
    it_should_behave_like "a key delete command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyDelete) }
      let(:params) { %w{charmander charmander-key} }
    end
  end

  describe Chef::Knife::ClientKeyDelete do
    it_should_behave_like "a key delete command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyDelete) }
      let(:params) { %w{charmander charmander-key} }
    end
  end
end

describe Chef::Knife::KeyDelete do
  let(:actor) { "charmander" }
  let(:keyname) { "charmander-key" }
  let(:ui) { instance_double("Chef::Knife::UI") }

  shared_examples_for "key delete run command" do
    let(:key_delete_object) do
      described_class.new(keyname, actor, actor_field_name, ui)
    end

    before do
      allow_any_instance_of(Chef::Key).to receive(:destroy)
      allow(key_delete_object).to receive(:print_destroyed)
      allow(key_delete_object).to receive(:confirm!)
    end

    context "when the command is run" do
      it "calls Chef::Key.new with the proper input" do
        expect(Chef::Key).to receive(:new).with(actor, actor_field_name).and_call_original
        key_delete_object.run
      end

      it "calls name on the Chef::Key instance with the proper input" do
        expect_any_instance_of(Chef::Key).to receive(:name).with(keyname)
        key_delete_object.run
      end

      it "calls destroy on the Chef::Key instance" do
        expect_any_instance_of(Chef::Key).to receive(:destroy).once
        key_delete_object.run
      end

      it "calls confirm!" do
        expect(key_delete_object).to receive(:confirm!)
        key_delete_object.run
      end

      it "calls print_destroyed" do
        expect(key_delete_object).to receive(:print_destroyed)
        key_delete_object.run
      end
    end # when the command is run

  end # key delete run command

  context "when actor_field_name is 'user'" do
    it_should_behave_like "key delete run command" do
      let(:actor_field_name) { "user" }
    end
  end

  context "when actor_field_name is 'client'" do
    it_should_behave_like "key delete run command" do
      let(:actor_field_name) { "client" }
    end
  end
end
