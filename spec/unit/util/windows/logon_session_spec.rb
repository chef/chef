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
require "chef/util/windows/logon_session"

describe ::Chef::Util::Windows::LogonSession do
  before do
    stub_const("Chef::ReservedNames::Win32::API::Security", Class.new)
    stub_const("Chef::ReservedNames::Win32::API::Security::LOGON32_LOGON_NEW_CREDENTIALS", 314)
    stub_const("Chef::ReservedNames::Win32::API::Security::LOGON32_PROVIDER_DEFAULT", 159)
    stub_const("Chef::ReservedNames::Win32::API::System", Class.new )
  end

  let(:session) { ::Chef::Util::Windows::LogonSession.new(session_user, password, session_domain, authentication) }
  let(:authentication) { :remote }

  shared_examples_for "it received syntactically invalid credentials" do
    it "does not raises an exception when it is initialized" do
      expect { session }.to raise_error(ArgumentError)
    end
  end

  shared_examples_for "it received an incorrect username and password combination" do
    before do
      expect(Chef::ReservedNames::Win32::API::Security).to receive(:LogonUserW).and_return(false)
    end

    it "raises a Chef::Exceptions::Win32APIError exception when the open method is called" do
      expect { session.open }.to raise_error(Chef::Exceptions::Win32APIError)
      expect(session).not_to receive(:close)
      expect(Chef::ReservedNames::Win32::API::System).not_to receive(:CloseHandle)
    end
  end

  shared_examples_for "it received valid credentials" do
    it "does not raise an exception when the open method is called" do
      expect(Chef::ReservedNames::Win32::API::Security).to receive(:LogonUserW).and_return(true)
      expect { session.open }.not_to raise_error
    end
  end

  shared_examples_for "the session is not open" do
    it "does not raise an exception when #open is called" do
      expect(Chef::ReservedNames::Win32::API::Security).to receive(:LogonUserW).and_return(true)
      expect { session.open }.not_to raise_error
    end

    it "raises an exception if #close is called" do
      expect { session.close }.to raise_error(RuntimeError)
    end

    it "raises an exception if #restore_user_context is called" do
      expect { session.restore_user_context }.to raise_error(RuntimeError)
    end
  end

  shared_examples_for "the session is open" do
    before do
      allow(Chef::ReservedNames::Win32::API::System).to receive(:CloseHandle)
    end
    it "does not result in an exception when #restore_user_context is called" do
      expect { session.restore_user_context }.not_to raise_error
    end

    it "does not result in an exception when #close is called" do
      expect { session.close }.not_to raise_error
    end

    it "does close the operating system handle when #close is called" do
      expect(Chef::ReservedNames::Win32::API::System).not_to receive(:CloseHandle)
      expect { session.restore_user_context }.not_to raise_error
    end
  end

  context "when the session is initialized with a nil user" do
    context "when the password, and domain are all nil" do
      let(:session_user) { nil }
      let(:session_domain) { nil }
      let(:password) { nil }
      it_behaves_like "it received syntactically invalid credentials"
    end

    context "when the password is non-nil password, and the domain is nil" do
      let(:session_user) { nil }
      let(:password) { "ponies" }
      let(:session_domain) { nil }
      it_behaves_like "it received syntactically invalid credentials"
    end

    context "when the password is nil and the domain is non-nil" do
      let(:session_user) { nil }
      let(:password) { nil }
      let(:session_domain) { "fairyland" }
      it_behaves_like "it received syntactically invalid credentials"
    end

    context "when the password and domain are non-nil" do
      let(:session_user) { nil }
      let(:password) { "ponies" }
      let(:session_domain) { "fairyland" }
      it_behaves_like "it received syntactically invalid credentials"
    end
  end

  context "when the session is initialized with a valid user" do
    let(:session_user) { "chalena" }

    context "when the password is nil" do
      let(:password) { nil }
      context "when the domain is non-nil" do
        let(:session_domain) { "fairyland" }
        it_behaves_like "it received syntactically invalid credentials"
      end

      context "when the domain is nil" do
        context "when the domain is non-nil" do
          let(:session_domain) { nil }
          it_behaves_like "it received syntactically invalid credentials"
        end
      end
    end

    context "when a syntactically valid username and password are supplied" do
      context "when the password is non-nil and the domain is nil" do
        let(:password) { "ponies" }
        let(:session_domain) { nil }
        it "does not raise an exception if it is initialized with a non-nil username, non-nil password, and a nil domain" do
          expect { session }.not_to raise_error
        end

        it_behaves_like "it received valid credentials"
        it_behaves_like "it received an incorrect username and password combination"
      end

      context "when the password and domain are non-nil" do
        let(:password) { "ponies" }
        let(:session_domain) { "fairyland" }
        it "does not raise an exception if it is initialized with a non-nil username, non-nil password, and non-nil domain" do
          expect { session }.not_to raise_error
        end

        it_behaves_like "it received valid credentials"
        it_behaves_like "it received an incorrect username and password combination"
      end

      context "when the #open method has not been called" do
        let(:password) { "ponies" }
        let(:session_domain) { "fairyland" }
        it_behaves_like "the session is not open"
      end

      context "when the session was opened" do
        let(:password) { "ponies" }
        let(:session_domain) { "fairyland" }

        before do
          expect(Chef::ReservedNames::Win32::API::Security).to receive(:LogonUserW).and_return(true)
          expect { session.open }.not_to raise_error
        end

        it "raises an exception if #open is called" do
          expect { session.open }.to raise_error(RuntimeError)
        end

        context "when the session was opened and then closed with the #close method" do
          before do
            expect(Chef::ReservedNames::Win32::API::System).to receive(:CloseHandle)
            expect { session.close }.not_to raise_error
          end
          it_behaves_like "the session is not open"
        end

        it "can be closed and close the operating system handle" do
          expect(Chef::ReservedNames::Win32::API::System).to receive(:CloseHandle)
          expect { session.close }.not_to raise_error
        end

        it "can impersonate the user" do
          expect(Chef::ReservedNames::Win32::API::Security).to receive(:ImpersonateLoggedOnUser).and_return(true)
          expect { session.set_user_context }.not_to raise_error
        end

        context "when #set_user_context fails due to low resources causing a failure to impersonate" do
          before do
            expect(Chef::ReservedNames::Win32::API::Security).to receive(:ImpersonateLoggedOnUser).and_return(false)
          end

          it "raises an exception when #set_user_context fails because impersonation failed" do
            expect { session.set_user_context }.to raise_error(Chef::Exceptions::Win32APIError)
          end

          context "when calling subsequent methods" do
            before do
              expect { session.set_user_context }.to raise_error(Chef::Exceptions::Win32APIError)
              expect(Chef::ReservedNames::Win32::API::Security).not_to receive(:RevertToSelf)
            end

            it_behaves_like "the session is open"
          end
        end

        context "when #set_user_context successfully impersonates the user" do
          before do
            expect(Chef::ReservedNames::Win32::API::Security).to receive(:ImpersonateLoggedOnUser).and_return(true)
            expect { session.set_user_context }.not_to raise_error
          end

          context "when attempting to impersonate while already impersonating" do
            it "raises an error if the #set_user_context is called again" do
              expect { session.set_user_context }.to raise_error(RuntimeError)
            end
          end

          describe "the impersonation will be reverted" do
            before do
              expect(Chef::ReservedNames::Win32::API::Security).to receive(:RevertToSelf).and_return(true)
            end
            it_behaves_like "the session is open"
          end

          context "when the attempt to revert impersonation fails" do
            before do
              expect(Chef::ReservedNames::Win32::API::Security).to receive(:RevertToSelf).and_return(false)
            end

            it "raises an exception when #restore_user_context is called" do
              expect { session.restore_user_context }.to raise_error(Chef::Exceptions::Win32APIError)
            end

            it "raises an exception when #close is called and impersonation fails" do
              expect { session.close }.to raise_error(Chef::Exceptions::Win32APIError)
            end

            context "when calling methods after revert fails in #restore_user_context" do
              before do
                expect { session.restore_user_context }.to raise_error(Chef::Exceptions::Win32APIError)
              end

              context "when revert continues to fail" do
                before do
                  expect(Chef::ReservedNames::Win32::API::Security).to receive(:RevertToSelf).and_return(false)
                end
                it "raises an exception when #close is called and impersonation fails" do
                  expect { session.close }.to raise_error(Chef::Exceptions::Win32APIError)
                end
              end

              context "when revert stops failing and succeeds" do
                before do
                  expect(Chef::ReservedNames::Win32::API::Security).to receive(:RevertToSelf).and_return(true)
                end

                it "does not raise an exception when #restore_user_context is called" do
                  expect { session.restore_user_context }.not_to raise_error
                end

                it "does not raise an exception when #close is called" do
                  expect(Chef::ReservedNames::Win32::API::System).to receive(:CloseHandle)
                  expect { session.close }.not_to raise_error
                end
              end
            end
          end
        end

      end
    end
  end
end
