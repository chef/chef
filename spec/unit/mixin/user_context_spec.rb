#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require "spec_helper"
require "chef/mixin/user_context"
require "chef/util/windows/logon_session"

describe "a class that mixes in user_context" do
  let(:instance_with_user_context) do
    class UserContextConsumer
      include ::Chef::Mixin::UserContext
      def with_context(user, domain, password, &block)
        with_user_context(user, password, domain, &block)
      end
    end
    UserContextConsumer.new
  end

  shared_examples_for "a method that requires a block" do
    it "raises an ArgumentError exception if a block is not supplied" do
      expect { instance_with_user_context.with_context(nil, nil, nil) }.to raise_error(ArgumentError)
    end
  end

  context "when running on Windows" do
    before do
      allow(ChefUtils).to receive(:windows?).and_return(true)
      allow(::Chef::Util::Windows::LogonSession).to receive(:new).and_return(logon_session)
    end

    let(:logon_session) { instance_double("::Chef::Util::Windows::LogonSession", set_user_context: nil, open: nil, close: nil) }

    it "does not raise an exception when the user and all parameters are nil" do
      expect { instance_with_user_context.with_context(nil, nil, nil) {} }.not_to raise_error
    end

    context "when given valid user credentials" do
      before do
        expect(::Chef::Util::Windows::LogonSession).to receive(:new).and_return(logon_session)
      end

      let(:block_object) do
        class BlockClass
          def block_method; end
        end
        BlockClass.new
      end

      let(:block_parameter) { Proc.new { block_object.block_method } }

      context "when the block doesn't raise an exception" do
        before do
          expect( block_object ).to receive(:block_method)
        end
        it "calls the supplied block" do
          expect { instance_with_user_context.with_context("kamilah", nil, "chef4life", &block_parameter) }.not_to raise_error
        end

        it "does not raise an exception if the user, password, and domain are specified" do
          expect { instance_with_user_context.with_context("kamilah", "xanadu", "chef4life", &block_parameter) }.not_to raise_error
        end
      end

      context "when the block raises an exception" do
        it "closes the logon session so resources are not leaked" do
          expect(logon_session).to receive(:close)
          expect { instance_with_user_context.with_context("kamilah", nil, "chef4life") { 1 / 0 } }.to raise_error(ZeroDivisionError)
        end
      end
    end

    it_behaves_like "a method that requires a block"
  end

  context "when not running on Windows" do
    before do
      allow(ChefUtils).to receive(:windows?).and_return(false)
    end

    it "raises a ::Chef::Exceptions::UnsupportedPlatform exception" do
      expect { instance_with_user_context.with_context(nil, nil, nil) {} }.to raise_error(::Chef::Exceptions::UnsupportedPlatform)
    end
  end
end
