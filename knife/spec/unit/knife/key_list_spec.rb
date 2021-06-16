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
require "chef/knife/user_key_list"
require "chef/knife/client_key_list"
require "chef/knife/key_list"
require "chef/key"

describe "key list commands that inherit knife" do
  shared_examples_for "a key list command" do
    let(:stderr) { StringIO.new }
    let(:params) { [] }
    let(:service_object) { instance_double(Chef::Knife::KeyList) }
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
        it "creates a new instance of Chef::Knife::KeyList with the correct args" do
          expect(Chef::Knife::KeyList).to receive(:new)
            .with("charmander", command.list_method, command.ui, command.config)
            .and_return(service_object)
          command.service_object
        end
      end # when the service object is called
    end # after apply_params! is called with valid args
  end # a key list command

  describe Chef::Knife::UserKeyList do
    it_should_behave_like "a key list command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyList) }
      let(:params) { ["charmander"] }
    end
  end

  describe Chef::Knife::ClientKeyList do
    it_should_behave_like "a key list command"
    # defined in key_helpers.rb
    it_should_behave_like "a knife key command" do
      let(:service_object) { instance_double(Chef::Knife::KeyList) }
      let(:params) { ["charmander"] }
    end
  end
end

describe Chef::Knife::KeyList do
  let(:config) { {} }
  let(:actor) { "charmander" }
  let(:ui) { instance_double("Chef::Knife::UI") }

  shared_examples_for "key list run command" do
    let(:key_list_object) do
      described_class.new(actor, list_method, ui, config)
    end

    before do
      allow(Chef::Key).to receive(list_method).and_return(http_response)
      allow(key_list_object).to receive(:display_info)
      # simply pass the string though that colorize takes in
      allow(key_list_object).to receive(:colorize).with(kind_of(String)) do |input|
        input
      end
    end

    context "when only_expired and only_non_expired were both passed" do
      before do
        key_list_object.config[:only_expired] = true
        key_list_object.config[:only_non_expired] = true
      end

      it "raises a Chef::Exceptions::KeyCommandInputError with the proper error message" do
        expect { key_list_object.run }.to raise_error(Chef::Exceptions::KeyCommandInputError, key_list_object.expired_and_non_expired_msg)
      end
    end

    context "when the command is run" do
      before do
        key_list_object.config[:only_expired] = false
        key_list_object.config[:only_non_expired] = false
        key_list_object.config[:with_details] = false
      end

      it "calls Chef::Key with the proper list command and input" do
        expect(Chef::Key).to receive(list_method).with(actor)
        key_list_object.run
      end

      it "displays all the keys" do
        expect(key_list_object).to receive(:display_info).with(/non-expired/).twice
        expect(key_list_object).to receive(:display_info).with(/out-of-date/).once
        key_list_object.run
      end

      context "when only_expired is called" do
        before do
          key_list_object.config[:only_expired] = true
        end

        it "excludes displaying non-expired keys" do
          expect(key_list_object).to receive(:display_info).with(/non-expired/).exactly(0).times
          key_list_object.run
        end

        it "displays the expired keys" do
          expect(key_list_object).to receive(:display_info).with(/out-of-date/).once
          key_list_object.run
        end
      end # when only_expired is called

      context "when only_non_expired is called" do
        before do
          key_list_object.config[:only_non_expired] = true
        end

        it "excludes displaying expired keys" do
          expect(key_list_object).to receive(:display_info).with(/out-of-date/).exactly(0).times
          key_list_object.run
        end

        it "displays the non-expired keys" do
          expect(key_list_object).to receive(:display_info).with(/non-expired/).twice
          key_list_object.run
        end
      end # when only_expired is called

      context "when with_details is false" do
        before do
          key_list_object.config[:with_details] = false
        end

        it "does not display the uri" do
          expect(key_list_object).to receive(:display_info).with(/https/).exactly(0).times
          key_list_object.run
        end

        it "does not display the expired status" do
          expect(key_list_object).to receive(:display_info).with(/\(expired\)/).exactly(0).times
          key_list_object.run
        end
      end # when with_details is false

      context "when with_details is true" do
        before do
          key_list_object.config[:with_details] = true
        end

        it "displays the uri" do
          expect(key_list_object).to receive(:display_info).with(/https/).exactly(3).times
          key_list_object.run
        end

        it "displays the expired status" do
          expect(key_list_object).to receive(:display_info).with(/\(expired\)/).once
          key_list_object.run
        end
      end # when with_details is true

    end # when the command is run

  end # key list run command

  context "when list_method is :list_by_user" do
    it_should_behave_like "key list run command" do
      let(:list_method) { :list_by_user }
      let(:http_response) do
        [
          { "uri" => "https://api.opscode.piab/users/charmander/keys/non-expired1", "name" => "non-expired1", "expired" => false },
          { "uri" => "https://api.opscode.piab/users/charmander/keys/non-expired2", "name" => "non-expired2", "expired" => false },
          { "uri" => "https://api.opscode.piab/users/mary/keys/out-of-date",        "name" => "out-of-date", "expired" => true },
        ]
      end
    end
  end

  context "when list_method is :list_by_client" do
    it_should_behave_like "key list run command" do
      let(:list_method) { :list_by_client }
      let(:http_response) do
        [
          { "uri" => "https://api.opscode.piab/organizations/pokemon/clients/charmander/keys/non-expired1", "name" => "non-expired1", "expired" => false },
          { "uri" => "https://api.opscode.piab/organizations/pokemon/clients/charmander/keys/non-expired2", "name" => "non-expired2", "expired" => false },
          { "uri" => "https://api.opscode.piab/organizations/pokemon/clients/mary/keys/out-of-date",        "name" => "out-of-date", "expired" => true },
        ]
      end
    end
  end
end
