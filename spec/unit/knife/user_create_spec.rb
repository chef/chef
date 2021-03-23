#
# Author:: Steven Danna (<steve@chef.io>)
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

Chef::Knife::UserCreate.load_deps

describe Chef::Knife::UserCreate do

  let(:knife) { Chef::Knife::UserCreate.new }
  let(:root_rest) { double("Chef::ServerAPI") }

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

  let(:chef_root_rest_v0) { double("Chef::ServerAPI") }

  context "when USERNAME isn't specified" do
    # from spec/support/shared/unit/knife_shared.rb
    it_should_behave_like "mandatory field missing" do
      let(:name_args) { [] }
      let(:fieldname) { "username" }
    end
  end

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

  describe "with prompt password" do
    let(:name_args) { %w{some_user some_display_name some_first_name some_last_name test@email.com} }

    before :each do
      @user = double("Chef::User")
      @key = "You don't come into cooking to get rich - Ramsay"
      allow(@user).to receive(:[]).with("private_key").and_return(@key)
      knife.config[:passwordprompt] = true
      knife.name_args = name_args
    end

    it "creates an user" do
      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
      expect(root_rest).to receive(:post).and_return(@user)
      expect(knife.ui).to receive(:ask).with("Please enter the user's password: ", echo: false).and_return("password")
      knife.run
    end
  end

  context "when all mandatory fields are validly specified" do
    before do
      @user = double("Chef::User")
      @key = "You don't come into cooking to get rich - Ramsay"
      allow(@user).to receive(:[]).with("private_key").and_return(@key)
      knife.name_args = %w{some_user some_display_name some_first_name some_last_name some_email some_password}
    end

    it "sets all the mandatory fields" do
      expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
      expect(root_rest).to receive(:post).and_return(@user)
      knife.run
      expect(knife.user.username).to eq("some_user")
      expect(knife.user.display_name).to eq("some_display_name")
      expect(knife.user.first_name).to eq("some_first_name")
      expect(knife.user.last_name).to eq("some_last_name")
      expect(knife.user.email).to eq("some_email")
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
        expect(stderr.string).to match(/You cannot pass --user-key and --prevent-keygen/)
      end
    end

    context "when --prevent-keygen is passed" do
      before do
        knife.config[:prevent_keygen] = true
      end

      it "does not set user.create_key" do
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
        knife.run
        expect(knife.user.create_key).to be_falsey
      end
    end

    context "when --prevent-keygen is not passed" do
      it "sets user.create_key to true" do
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
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
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
        knife.run
        expect(knife.user.public_key).to eq("some_key")
      end
    end

    context "when --user-key is not passed" do
      it "does not set user.public_key" do
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
        knife.run
        expect(knife.user.public_key).to be_nil
      end
    end

    describe "with user_name, first_name, last_name, email and password" do
      let(:name_args) { %w{some_user some_display_name some_first_name some_last_name test@email.com some_password} }

      before :each do
        @user = double("Chef::User")
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
        @key = "You don't come into cooking to get rich - Ramsay"
        allow(@user).to receive(:[]).with("private_key").and_return(@key)
        knife.name_args = name_args
      end

      it "creates an user" do
        expect(knife.ui).to receive(:msg).with(@key)
        knife.run
      end

      context "with --orgname" do
        before :each do
          knife.config[:orgname] = "ramsay"
          @uri = "http://www.example.com/1"
          allow(@user).to receive(:[]).with("uri").and_return(@uri)
        end

        let(:request_body) {
          { user: "some_user" }
        }

        it "creates an user, associates a user, and adds it to the admins group" do

          expect(root_rest).to receive(:post).with("organizations/ramsay/association_requests", request_body).and_return(@user)
          expect(root_rest).to receive(:put).with("users/some_user/association_requests/1", { response: "accept" })
          knife.run
        end
      end
    end

    describe "user user_name, --email, --password" do
      let(:name_args) { %w{some_user} }

      before :each do
        @user = double("Chef::User")
        expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
        expect(root_rest).to receive(:post).and_return(@user)
        @key = "You don't come into cooking to get rich - Ramsay"
        allow(@user).to receive(:[]).with("private_key").and_return(@key)
        knife.name_args = name_args
        knife.config[:email] = "test@email.com"
        knife.config[:password] = "some_password"
      end

      it "creates an user" do
        expect(knife.ui).to receive(:msg).with(@key)
        knife.run
      end

      context "with --orgname" do
        before :each do
          knife.config[:orgname] = "ramsay"
          @uri = "http://www.example.com/1"
          allow(@user).to receive(:[]).with("uri").and_return(@uri)
        end

        let(:request_body) {
          { user: "some_user" }
        }

        it "creates an user, associates a user, and adds it to the admins group" do

          expect(root_rest).to receive(:post).with("organizations/ramsay/association_requests", request_body).and_return(@user)
          expect(root_rest).to receive(:put).with("users/some_user/association_requests/1", { response: "accept" })
          knife.run
        end
      end

    end

  end # when all mandatory fields are validly specified
end
