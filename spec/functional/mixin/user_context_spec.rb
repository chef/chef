#
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

require 'chef/win32/api' if Chef::Platform.windows?
require 'chef/win32/api/error' if Chef::Platform.windows?
require 'chef/mixin/user_context'

describe Chef::Mixin::UserContext, windows_only: true do
  include Chef::Mixin::UserContext

  let(:get_user_name_a) do
    FFI::ffi_lib 'advapi32.dll'
    FFI::attach_function :GetUserNameA, [ :pointer, :pointer ], :bool
  end

  let(:process_username) do
    name_size = FFI::Buffer.new(:long).write_long(0)
    succeeded = get_user_name_a.call(nil, name_size)
    last_error = FFI::LastError.error
    if succeeded || last_error != Chef::ReservedNames::Win32::API::Error::ERROR_INSUFFICIENT_BUFFER
      raise Chef::Exceptions::Win32APIError, "Expected ERROR_INSUFFICIENT_BUFFER from GetUserNameA but it returned the following error: #{last_error}"
    end
    user_name = FFI::MemoryPointer.new :char, (name_size.read_long)
    succeeded = get_user_name_a.call(user_name, name_size)
    last_error = FFI::LastError.error
    if succeeded == 0 || last_error != 0
      raise Chef::Exceptions::Win32APIError, "GetUserNameA failed with #{lasterror}"
    end
    user_name.read_string
  end

  let(:test_user) { 'chefuserctx3' }
  let(:test_domain) { windows_nonadmin_user_domain }
  let(:test_password) { 'j823jfxK3;2Xe1' }

  let(:username_domain_qualification) { nil }
  let(:username_with_conditional_domain) { username_domain_qualification.nil? ? username_to_impersonate : "#{username_domain_qualification}\\#{username_to_impersonate}" }

  let(:windows_nonadmin_user) { test_user }
  let(:windows_nonadmin_user_password) { test_password }

  let(:username_while_impersonating) do
    username = nil
    with_user_context(username_with_conditional_domain, username_to_impersonate_password, domain_to_impersonate) do
      username = process_username
    end
    username
  end

  shared_examples_for "method that executes the block while impersonating the alternate user" do
    it "sets the current thread token to that of the alternate user when the correct password is specified" do
      expect(username_while_impersonating.downcase).to eq(username_to_impersonate.downcase)
    end
  end

  describe "#with_user_context" do
    context "when the user and domain are both nil" do
      let(:username_to_impersonate) { nil }
      let(:domain_to_impersonate) { nil }
      let(:username_to_impersonate_password) { nil }

      it "has the same token and username as the process" do
        expect(username_while_impersonating.downcase).to eq(ENV['username'].downcase)
      end
    end

    context "when a non-nil user is specified" do
      include_context "a non-admin Windows user"
      context "when a username different than the process user is specified" do
        let(:username_to_impersonate) { test_user }
        let(:username_to_impersonate_password) { test_password }
        context "when an explicit domain is given with a valid password" do
          let(:domain_to_impersonate) { test_domain }
          it "sets the current thread token to that of the alternate user when the correct password is specified" do
            expect(username_while_impersonating.downcase).to eq(username_to_impersonate.downcase)
          end
        end

        context "when a valid password and a non-qualified user is given and no domain is specified" do
          let(:domain_to_impersonate) { nil }
          it_behaves_like "method that executes the block while impersonating the alternate user"
        end

        context "when a valid password and a qualified user is given and no domain is specified" do
          let(:domain_to_impersonate) { nil }
          let(:username_domain_qualification) { test_domain }
          it_behaves_like "method that executes the block while impersonating the alternate user"
        end

        it "raises an error user if specified with the wrong password" do
          expect { with_user_context(username_to_impersonate, username_to_impersonate_password + '1', nil) }.to raise_error(ArgumentError)
        end
      end
    end

    context "when invalid arguments are passed" do
      it "raises an ArgumentError exception if the password is not specified but the user is specified" do
        expect { with_user_context(test_user, nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
