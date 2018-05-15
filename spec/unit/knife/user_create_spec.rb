#
# Author:: Steven Danna (<steve@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

Chef::Knife::UserCreate.load_deps

describe Chef::Knife::UserCreate do
  let(:knife) { Chef::Knife::UserCreate.new }

  let(:stderr) do
    StringIO.new
  end

  let(:stdout) do
    StringIO.new
  end

  before(:each) do
    allow(knife.ui).to receive(:stdout).and_return(stdout)
    allow(knife.ui).to receive(:stderr).and_return(stderr)
    allow(knife.ui).to receive(:warn)
  end

  # delete this once OSC11 support is gone
  context "when only one name_arg is passed" do
    before do
      knife.name_args = ["some_user"]
      allow(knife).to receive(:run_osc_11_user_create).and_raise(SystemExit)
    end

    it "displays the osc warning" do
      expect(knife.ui).to receive(:warn).with(knife.osc_11_warning)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "calls knife osc_user create" do
      expect(knife).to receive(:run_osc_11_user_create)
      expect { knife.run }.to raise_error(SystemExit)
    end

  end

  context "when USERNAME isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { [] }
      let(:fieldname) { "username" }
    end
  end

  # uncomment once OSC11 support is gone,
  # pending doesn't work for shared_examples_for by default
  #
  # context "when DISPLAY_NAME isn't specified" do
  #   # from spec/support/shared/unit/knife_shared.rb
  #   it_should_behave_like "mandatory field missing" do
  #     let(:name_args) { ['some_user'] }
  #     let(:fieldname) { 'display name' }
  #   end
  # end

  context "when FIRST_NAME isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { %w{some_user some_display_name} }
      let(:fieldname) { "first name" }
    end
  end

  context "when LAST_NAME isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { %w{some_user some_display_name some_first_name} }
      let(:fieldname) { "last name" }
    end
  end

  context "when EMAIL isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { %w{some_user some_display_name some_first_name some_last_name} }
      let(:fieldname) { "email" }
    end
  end

  context "when PASSWORD isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { %w{some_user some_display_name some_first_name some_last_name some_email} }
      let(:fieldname) { "password" }
    end
  end

  context "when all mandatory fields are validly specified" do
    before do
      knife.name_args = %w{some_user some_display_name some_first_name some_last_name some_email some_password}
      allow(knife).to receive(:edit_hash).and_return(knife.user.to_hash)
      allow(knife).to receive(:create_user_from_hash).and_return(knife.user)
    end

    before(:each) do
      # reset the user field every run
      knife.user_field = nil
    end

    it "sets all the mandatory fields" do
      knife.run
      expect(knife.user.username).to eq("some_user")
      expect(knife.user.display_name).to eq("some_display_name")
      expect(knife.user.first_name).to eq("some_first_name")
      expect(knife.user.last_name).to eq("some_last_name")
      expect(knife.user.email).to eq("some_email")
      expect(knife.user.password).to eq("some_password")
    end

    context "when user_key and prevent_keygen are passed" do
      before do
        knife.config[:user_key] = "some_key"
        knife.config[:prevent_keygen] = true
      end
      it "prints the usage" do
        expect(knife).to receive(:show_usage)
        expect { knife.run }.to raise_error(SystemExit)
      end

      it "prints a relevant error message" do
        expect { knife.run }.to raise_error(SystemExit)
        expect(stderr.string).to match /You cannot pass --user-key and --prevent-keygen/
      end
    end

    context "when --prevent-keygen is passed" do
      before do
        knife.config[:prevent_keygen] = true
      end

      it "does not set user.create_key" do
        knife.run
        expect(knife.user.create_key).to be_falsey
      end
    end

    context "when --prevent-keygen is not passed" do
      it "sets user.create_key to true" do
        knife.run
        expect(knife.user.create_key).to be_truthy
      end
    end

    context "when --user-key is passed" do
      before do
        knife.config[:user_key] = "some_key"
        allow(File).to receive(:read).and_return("some_key")
        allow(File).to receive(:expand_path)
      end

      it "sets user.public_key" do
        knife.run
        expect(knife.user.public_key).to eq("some_key")
      end
    end

    context "when --user-key is not passed" do
      it "does not set user.public_key" do
        knife.run
        expect(knife.user.public_key).to be_nil
      end
    end

    context "when a private_key is returned" do
      before do
        allow(knife).to receive(:create_user_from_hash).and_return(Chef::UserV1.from_hash(knife.user.to_hash.merge({ "private_key" => "some_private_key" })))
      end

      context "when --file is passed" do
        before do
          knife.config[:file] = "/some/path"
        end

        it "creates a new file of the path passed" do
          filehandle = double("filehandle")
          expect(filehandle).to receive(:print).with("some_private_key")
          expect(File).to receive(:open).with("/some/path", "w").and_yield(filehandle)
          knife.run
        end
      end

      context "when --file is not passed" do
        it "prints the private key to stdout" do
          expect(knife.ui).to receive(:msg).with("some_private_key")
          knife.run
        end
      end
    end

  end # when all mandatory fields are validly specified
end
