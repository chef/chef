#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software
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
require "chef/mixin/unformatter"

class Chef::UnformatterTest
  include Chef::Mixin::Unformatter

  def foo
  end

end

describe Chef::Mixin::Unformatter do
  let (:unformatter) { Chef::UnformatterTest.new }
  let (:message) { "Test Message" }

  describe "#write" do
    context "with a timestamp" do
      it "sends foo to itself when the message is of severity foo" do
        expect(unformatter).to receive(:foo).with(message)
        unformatter.write("[time] foo: #{message}")
      end

      it "sends foo to itself when the message is of severity FOO" do
        expect(unformatter).to receive(:foo).with(message)
        unformatter.write("[time] FOO: #{message}")
      end
    end

    context "without a timestamp" do
      it "sends foo to itself when the message is of severity foo" do
        expect(unformatter).to receive(:foo).with(message)
        unformatter.write("foo: #{message}")
      end

      it "sends foo to itself when the message is of severity FOO" do
        expect(unformatter).to receive(:foo).with(message)
        unformatter.write("FOO: #{message}")
      end
    end

  end

end
