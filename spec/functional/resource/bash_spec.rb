#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
require "functional/resource/base"

describe Chef::Resource::Bash, :unix_only do
  let(:code) { "echo hello" }
  let(:resource) do
    resource = Chef::Resource::Bash.new("foo_resource", run_context)
    resource.code(code) unless code.nil?
    resource
  end

  describe "when setting the command attribute" do
    let (:command) { "wizard racket" }

    it "should raise an exception when trying to set the command" do
      expect { resource.command command }.to raise_error(Chef::Exceptions::Script)
    end

    it "should initialize the command to nil" do
      expect(resource.command).to be_nil
    end

    describe "when the code is not present" do
      let(:code) { nil }
      it "raises an exception" do
        expect { resource.run_action(:run) }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end

  it "times out when a timeout is set on the resource" do
    resource.code "sleep 600"
    resource.timeout 0.1
    expect { resource.run_action(:run) }.to raise_error(Mixlib::ShellOut::CommandTimeout)
  end
end
