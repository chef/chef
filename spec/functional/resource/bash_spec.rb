#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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
  let(:resource) {
    resource = Chef::Resource::Bash.new("foo_resource", run_context)
    resource.code(code)
    resource
  }

  describe "when setting the command attribute" do
    let (:command) { "wizard racket" }

    # in Chef-12 the `command` attribute is largely useless, but does set the identity attribute
    # so that notifications need to target the value of the command.  it will not run the `command`
    # and if it is given without a code block then it does nothing and always succeeds.
    describe "in Chef-12", chef: "< 13" do
      it "gets the commmand attribute from the name" do
        expect(resource.command).to eql("foo_resource")
      end

      it "sets the resource identity to the command name" do
        resource.command command
        expect(resource.identity).to eql(command)
      end

      it "warns when the code is not present and a useless `command` is present" do
        expect(Chef::Log).to receive(:warn).with(/coding error/)
        expect(Chef::Log).to receive(:warn).with(/deprecated/)
        resource.code nil
        resource.command command
        expect { resource.run_action(:run) }.not_to raise_error
      end

      describe "when the code is not present" do
        let(:code) { nil }
        it "warns" do
          expect(Chef::Log).to receive(:warn)
          expect { resource.run_action(:run) }.not_to raise_error
        end
      end
    end

    # in Chef-13 the `command` attribute needs to be for internal use only
    describe "in Chef-13", chef: ">= 13" do
      it "should raise an exception when trying to set the command" do
        expect { resource.command command }.to raise_error # FIXME: add a real error in Chef-13
      end

      it "should initialize the command to nil" do
        expect(resource.command).to be_nil
      end

      describe "when the code is not present" do
        let(:code) { nil }
        it "raises an exception" do
          expect { resource.run_action(:run) }.to raise_error # FIXME: add a real error in Chef-13
          expect { resource.run_action(:run) }.not_to raise_error
        end
      end
    end
  end

  it "times out when a timeout is set on the resource" do
    resource.code "sleep 600"
    resource.timeout 0.1
    expect { resource.run_action(:run) }.to raise_error(Mixlib::ShellOut::CommandTimeout)
  end
end
