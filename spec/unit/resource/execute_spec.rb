#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::Execute do
  let(:resource_instance_name) { "some command" }
  let(:execute_resource) { Chef::Resource::Execute.new(resource_instance_name) }
  it_behaves_like "an execute resource"

  it "default guard interpreter should be :execute interpreter" do
    expect(execute_resource.guard_interpreter).to be(:execute)
  end

  it "defaults to not being a guard interpreter" do
    expect(execute_resource.is_guard_interpreter).to eq(false)
  end

  describe "#qualify_user" do
    let(:password) { "password" }
    let(:domain) { nil }

    context "when username is passed as user@domain" do
      let(:username) { "user@domain" }

      it "correctly parses the user and domain" do
        identity = execute_resource.qualify_user(username, password, domain)
        expect(identity[:domain]).to eq("domain")
        expect(identity[:user]).to eq("user")
      end
    end

    context "when username is passed as domain\\user" do
      let(:username) { "domain\\user" }

      it "correctly parses the user and domain" do
        identity = execute_resource.qualify_user(username, password, domain)
        expect(identity[:domain]).to eq("domain")
        expect(identity[:user]).to eq("user")
      end
    end
  end

  shared_examples_for "it received valid credentials" do
    describe "the validation method" do
      it "should not raise an error" do
        expect { execute_resource.validate_identity_platform(username, password, domain) }.not_to raise_error
      end
    end

    describe "the name qualification method" do
      it "should correctly translate the user and domain" do
        identity = nil
        expect { identity = execute_resource.qualify_user(username, password, domain) }.not_to raise_error
        expect(identity[:domain]).to eq(domain)
        expect(identity[:user]).to eq(username)
      end
    end
  end

  shared_examples_for "it received invalid credentials" do
    describe "the validation method" do
      it "should raise an error" do
        expect { execute_resource.validate_identity_platform(username, password, domain) }.to raise_error(ArgumentError)
      end
    end
  end

  shared_examples_for "it received invalid username and domain" do
    describe "the validation method" do
      it "should raise an error" do
        expect { execute_resource.qualify_user(username, password, domain) }.to raise_error(ArgumentError)
      end
    end
  end

  shared_examples_for "it received credentials that are not valid on the platform" do
    describe "the validation method" do
      it "should raise an error" do
        expect { execute_resource.validate_identity_platform(username, password, domain) }.to raise_error(Chef::Exceptions::UnsupportedPlatform)
      end
    end
  end

  shared_examples_for "a consumer of the Execute resource" do
    context "when running on Windows" do
      before do
        allow(execute_resource).to receive(:node).and_return({ :platform_family => "windows" })
      end

      context "when no user, domain, or password is specified" do
        let(:username) { nil }
        let(:domain) { nil }
        let(:password) { nil }
        it_behaves_like "it received valid credentials"
      end

      context "when a valid username is specified" do
        let(:username) { "starchild" }
        context "when a valid domain is specified" do
          let(:domain) { "mothership" }

          context "when the password is not specified" do
            let(:password) { nil }
            it_behaves_like "it received invalid credentials"
          end

          context "when the password is specified" do
            let(:password) { "we.funk!" }
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
            let(:password) { "we.funk!" }
            it_behaves_like "it received valid credentials"
          end
        end

        context "when username is not specified" do
          let(:username) { nil }

          context "when domain is specified" do
            let(:domain) { "mothership" }
            let(:password) { nil }
            it_behaves_like "it received invalid username and domain"
          end

          context "when password is specified" do
            let(:domain) { nil }
            let(:password) { "we.funk!" }
            it_behaves_like "it received invalid username and domain"
          end
        end
      end

      context "when invalid username is specified" do
        let(:username) { "user@domain@domain" }
        let(:domain) { nil }
        let(:password) { "we.funk!" }
        it_behaves_like "it received invalid username and domain"
      end

      context "when the domain is provided in both username and domain" do
        let(:domain) { "some_domain" }
        let(:password) { "we.funk!" }

        context "when username is in the form domain\\user" do
          let(:username) { "mothership\\starchild" }
          it_behaves_like "it received invalid username and domain"
        end

        context "when username is in the form user@domain" do
          let(:username) { "starchild@mothership" }
          it_behaves_like "it received invalid username and domain"
        end
      end
    end

    context "when not running on Windows" do
      before do
        allow(execute_resource).to receive(:node).and_return({ :platform_family => "ubuntu" })
      end

      context "when no user, domain, or password is specified" do
        let(:username) { nil }
        let(:domain) { nil }
        let(:password) { nil }
        it_behaves_like "it received valid credentials"
      end

      context "when the user is specified and the domain and password are not" do
        let(:username) { "starchild" }
        let(:domain) { nil }
        let(:password) { nil }
        it_behaves_like "it received valid credentials"

        context "when the password is specified and the domain is not" do
          let(:password) { "we.funk!" }
          let(:domain) { nil }
          it_behaves_like "it received credentials that are not valid on the platform"
        end

        context "when the domain is specified and the password is not" do
          let(:domain) { "mothership" }
          let(:password) { nil }
          it_behaves_like "it received credentials that are not valid on the platform"
        end

        context "when the domain and password are specified" do
          let(:domain) { "mothership" }
          let(:password) { "we.funk!" }
          it_behaves_like "it received credentials that are not valid on the platform"
        end
      end

      context "when the user is not specified" do
        let(:username) { nil }
        context "when the domain is specified" do
          let(:domain) { "mothership" }
          context "when the password is specified" do
            let(:password) { "we.funk!" }
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
            let(:password) { "we.funk!" }
            it_behaves_like "it received credentials that are not valid on the platform"
          end
        end
      end
    end
  end

  it_behaves_like "a consumer of the Execute resource"

end
