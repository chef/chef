#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
require 'chef/mixin/user_identity'

shared_examples_for "it received valid credentials" do
  describe "the validation method" do
    it "should not raise an error" do
      expect {instance_with_identity.validate(username, password, domain)}.not_to raise_error
    end
  end

  describe "the name qualification method" do
    it "should correctly translate the user and domain" do
      identity = nil
      expect { identity = instance_with_identity.qualify_name(username, domain) }.not_to raise_error
      expect(identity[:domain]).to eq(domain)
      expect(identity[:user]).to eq(username)
    end
  end
end

shared_examples_for "it received invalid credentials" do
  describe "the validation method" do
    it "should raise an error" do
      expect { instance_with_identity.validate(username, password, domain)}.to raise_error(ArgumentError)
    end
  end
end

shared_examples_for "it received credentials that are not valid on the platform" do
  describe "the validation method" do
    it "should raise an error" do
      expect { instance_with_identity.validate(username, password, domain)}.to raise_error(Chef::Exceptions::UnsupportedPlatform)
    end
  end
end

shared_examples_for "a consumer of the ::Chef::Mixin::UserIdentity mixin" do
  context "when running on Windows" do
    before do
      allow(::Chef::Platform).to receive(:windows?).and_return(true)
    end

    context "when no user, domain, or password is specified" do
      let(:username) { nil }
      let(:domain) { nil }
      let(:password) { nil }
      it_behaves_like "it received valid credentials"
    end

    context "when a valid username is specified" do
      let(:username) { 'starchild' }
      context "when a valid domain is specified" do
        let(:domain) { 'mothership' }

        context "when the password is not specified" do
          let(:password) { nil }
          it_behaves_like "it received invalid credentials"
        end

        context "when the password is specified" do
          let(:password) { 'we.funk!' }
          it_behaves_like "it received valid credentials"
        end
      end

      context "when the domain is not specified" do
        let(:domain) { nil }

        context "when the password is not specified" do
          let(:password) { nil }
          it_behaves_like "it received invalid credentials"
        end

        context "when the password is specified" do
          let(:password) { 'we.funk!' }
          it_behaves_like "it received valid credentials"
        end
      end
    end

    context "when the username is not specified" do
      let(:username) { nil }

      context "when the password is specified and the domain is not" do
        let(:password) { 'we.funk!' }
        let(:domain) { nil }
        it_behaves_like "it received invalid credentials"
      end

      context "when the domain is specified and the password is not" do
        let(:domain) { 'mothership' }
        let(:password) { nil }
        it_behaves_like "it received invalid credentials"
      end

      context "when the domain and password are specified" do
        let(:domain) { 'mothership' }
        let(:password) { 'we.funk!' }
        it_behaves_like "it received invalid credentials"
      end
    end
  end

  context "when not running on Windows" do
    before do
      allow(::Chef::Platform).to receive(:windows?).and_return(false)
    end

    context "when no user, domain, or password is specified" do
      let(:username) { nil }
      let(:domain) { nil }
      let(:password) { nil }
      it_behaves_like "it received valid credentials"
    end

    context "when the user is specified and the domain and password are not" do
      let(:username) { 'starchild' }
      let(:domain) { nil }
      let(:password) { nil }
      it_behaves_like "it received valid credentials"

      context "when the password is specified and the domain is not" do
        let(:password) { 'we.funk!' }
        let(:domain) { nil }
        it_behaves_like "it received credentials that are not valid on the platform"
      end

      context "when the domain is specified and the password is not" do
        let(:domain) { 'mothership' }
        let(:password) { nil }
        it_behaves_like "it received credentials that are not valid on the platform"
      end

      context "when the domain and password are specified" do
        let(:domain) { 'mothership' }
        let(:password) { 'we.funk!' }
        it_behaves_like "it received credentials that are not valid on the platform"
      end
    end

    context "when the user is not specified" do
      let(:username) { nil }
      context "when the domain is specified" do
        let(:domain) { 'mothership' }
        context "when the password is specified" do
          let(:password) { 'we.funk!' }
          it_behaves_like "it received credentials that are not valid on the platform"
        end

        context "when password is not specified" do
          let(:password) { nil }
          it_behaves_like "it received credentials that are not valid on the platform"
        end
      end

      context "when the domain is not specified" do
        let(:domain) { nil }
        context "when the password is specified" do
          let(:password) { 'we.funk!' }
          it_behaves_like "it received credentials that are not valid on the platform"
        end
      end
    end
  end
end

describe "a class that mixes in user_identity" do
  let(:instance_with_identity) do
    class IdentityClass
      include ::Chef::Mixin::UserIdentity
      def validate(*args)
        validate_identity(*args)
      end

      def qualify_name(*args)
        qualify_user(*args)
      end
    end
    IdentityClass.new
  end

  it_behaves_like "a consumer of the ::Chef::Mixin::UserIdentity mixin"
end
