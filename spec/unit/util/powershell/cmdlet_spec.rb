#
# Author:: Jay Mundrawala <jdm@chef.io>
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef"
require "chef/util/powershell/cmdlet"

describe Chef::Util::Powershell::Cmdlet do
  before (:all) do
    @node = Chef::Node.new
    @cmdlet = Chef::Util::Powershell::Cmdlet.new(@node, "Some-Commandlet")
  end

  describe "#validate_switch_name!" do
    it "should not raise an error if a name contains all upper case letters" do
      @cmdlet.send(:validate_switch_name!, "HELLO")
    end

    it "should not raise an error if the name contains all lower case letters" do
      @cmdlet.send(:validate_switch_name!, "hello")
    end

    it "should not raise an error if no special characters are used except _" do
      @cmdlet.send(:validate_switch_name!, "hello_world")
    end

    %w{! @ # $ % ^ & * & * ( ) - = + \{ \} . ? < > \\ /}.each do |sym|
      it "raises an Argument error if it configuration name contains #{sym}" do
        expect do
          @cmdlet.send(:validate_switch_name!, "Hello#{sym}")
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "#escape_parameter_value" do
    # Is this list really complete?
    %w{` " # '}.each do |c|
      it "escapse #{c}" do
        expect(@cmdlet.send(:escape_parameter_value, "stuff #{c}")).to eql("stuff `#{c}")
      end
    end

    it "does not do anything to a string without special characters" do
      expect(@cmdlet.send(:escape_parameter_value, "stuff")).to eql("stuff")
    end
  end

  describe "#escape_string_parameter_value" do
    it "surrounds a string with ''" do
      expect(@cmdlet.send(:escape_string_parameter_value, "stuff")).to eql("'stuff'")
    end
  end

  describe "#command_switches_string" do
    it "raises an ArgumentError if the key is not a symbol" do
      expect do
        @cmdlet.send(:command_switches_string, { "foo" => "bar" })
      end.to raise_error(ArgumentError)
    end

    it "does not allow invalid switch names" do
      expect do
        @cmdlet.send(:command_switches_string, { :foo! => "bar" })
      end.to raise_error(ArgumentError)
    end

    it "ignores switches with a false value" do
      expect(@cmdlet.send(:command_switches_string, { foo: false })).to eql("")
    end

    it "should correctly handle a value type of string" do
      expect(@cmdlet.send(:command_switches_string, { foo: "bar" })).to eql("-foo 'bar'")
    end

    it "should correctly handle a value type of string even when it is 0 length" do
      expect(@cmdlet.send(:command_switches_string, { foo: "" })).to eql("-foo ''")
    end

    it "should not quote integers" do
      expect(@cmdlet.send(:command_switches_string, { foo: 1 })).to eql("-foo 1")
    end

    it "should not quote floats" do
      expect(@cmdlet.send(:command_switches_string, { foo: 1.0 })).to eql("-foo 1.0")
    end

    it "has just the switch when the value is true" do
      expect(@cmdlet.send(:command_switches_string, { foo: true })).to eql("-foo")
    end
  end
end
