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
require "chef/knife/user_key_show"
require "chef/knife/client_key_show"
require "chef/knife/key_show"
require "chef/key"

describe "key show commands that inherit knife" do
  shared_examples_for "a key show command" do
    let(:stderr) { StringIO.new }
    let(:params) { [] }
    let(:service_object) { instance_double(Chef::Knife::KeyShow) }
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
        it "creates a new instance of Chef::Knife::KeyShow with the correct args" do
          expect(Chef::Knife::KeyShow).to receive(:new)
            .with("charmander-key", "charmander", command.load_method, command.ui)
            .and_return(service_object)
          command.service_object
        end
      end # when the service object is called
    end # after apply_params! is called with valid args
  end # a key show command

  describe Chef::Knife::UserKeyShow do
    it_should_behave_like "a key show command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyShow) }
      let(:params) { %w{charmander charmander-key} }
    end
  end

  describe Chef::Knife::ClientKeyShow do
    it_should_behave_like "a key show command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command with a keyname as the second arg"
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyShow) }
      let(:params) { %w{charmander charmander-key} }
    end
  end
end

describe Chef::Knife::KeyShow do
  let(:actor) { "charmander" }
  let(:keyname) { "charmander" }
  let(:ui) { instance_double("Chef::Knife::UI") }
  let(:expected_hash) do
    {
      actor_field_name => "charmander",
      "name" => "charmander-key",
      "public_key" => "some-public-key",
      "expiration_date" => "infinity",
    }
  end

  shared_examples_for "key show run command" do
    let(:key_show_object) do
      described_class.new(keyname, actor, load_method, ui)
    end

    before do
      allow(key_show_object).to receive(:display_output)
      allow(Chef::Key).to receive(load_method).and_return(Chef::Key.from_hash(expected_hash))
    end

    context "when the command is run" do
      it "loads the key using the proper method and args" do
        expect(Chef::Key).to receive(load_method).with(actor, keyname)
        key_show_object.run
      end

      it "displays the key" do
        expect(key_show_object).to receive(:display_output)
        key_show_object.run
      end
    end
  end

  context "when load_method is :load_by_user" do
    it_should_behave_like "key show run command" do
      let(:load_method) { :load_by_user }
      let(:actor_field_name) { "user" }
    end
  end

  context "when load_method is :load_by_client" do
    it_should_behave_like "key show run command" do
      let(:load_method) { :load_by_client }
      let(:actor_field_name) { "user" }
    end
  end
end
