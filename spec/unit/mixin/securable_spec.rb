#
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Mixin::Securable do

  before(:each) do
    @securable = Object.new
    @securable.send(:extend, Chef::Mixin::Securable)
    @securable.send(:extend, Chef::Mixin::ParamsValidate)
  end

  it "should accept a group name or id for group" do
    lambda { @securable.group "root" }.should_not raise_error(ArgumentError)
    lambda { @securable.group 123 }.should_not raise_error(ArgumentError)
    lambda { @securable.group "root*goo" }.should raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    lambda { @securable.owner "root" }.should_not raise_error(ArgumentError)
    lambda { @securable.owner 123 }.should_not raise_error(ArgumentError)
    lambda { @securable.owner "root*goo" }.should raise_error(ArgumentError)
  end

  it "allows the owner to be specified as #user" do
    @securable.should respond_to(:user)
  end

  describe "unix-specific behavior" do
    before(:each) do
      platform_mock :unix do
        @original_config = Chef::Config.hash_dup
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "config.rb")
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "mixin", "securable.rb")
        @securable = Object.new
        @securable.send(:extend, Chef::Mixin::Securable)
        @securable.send(:extend, Chef::Mixin::ParamsValidate)
      end
    end

    after(:each) do
      Chef::Config.configuration = @original_config
    end

    it "should accept a group name or id for group with spaces and backslashes" do
      lambda { @securable.group 'test\ group' }.should_not raise_error(ArgumentError)
    end

    it "should accept a unix file mode in string form as an octal number" do
      lambda { @securable.mode "0" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0000" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0111" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0444" }.should_not raise_error(ArgumentError)

      lambda { @securable.mode "111" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "444" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "7777" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "07777" }.should_not raise_error(ArgumentError)

      lambda { @securable.mode "-01" }.should raise_error(ArgumentError)
      lambda { @securable.mode "010000" }.should raise_error(ArgumentError)
      lambda { @securable.mode "-1" }.should raise_error(ArgumentError)
      lambda { @securable.mode "10000" }.should raise_error(ArgumentError)

      lambda { @securable.mode "07778" }.should raise_error(ArgumentError)
      lambda { @securable.mode "7778" }.should raise_error(ArgumentError)
      lambda { @securable.mode "4095" }.should raise_error(ArgumentError)

      lambda { @securable.mode "0foo1234" }.should raise_error(ArgumentError)
      lambda { @securable.mode "foo1234" }.should raise_error(ArgumentError)
    end

    it "should accept a unix file mode in numeric form as a ruby-interpreted integer" do
      lambda { @securable.mode 0 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 0000 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 444 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 0444 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 07777 }.should_not raise_error(ArgumentError)

      lambda { @securable.mode 292 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 4095 }.should_not raise_error(ArgumentError)

      lambda { @securable.mode 0111 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 73 }.should_not raise_error(ArgumentError)

      lambda { @securable.mode -01 }.should raise_error(ArgumentError)
      lambda { @securable.mode 010000 }.should raise_error(ArgumentError)
      lambda { @securable.mode -1 }.should raise_error(ArgumentError)
      lambda { @securable.mode 4096 }.should raise_error(ArgumentError)
    end
  end

  describe "windows-specific behavior" do
    before(:each) do
      platform_mock :windows do
        @original_config = Chef::Config.hash_dup
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "config.rb")
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "mixin", "securable.rb")
        SECURABLE_CLASS = Class.new do
          include Chef::Mixin::Securable
          include Chef::Mixin::ParamsValidate
        end
        @securable = SECURABLE_CLASS.new
      end
    end

    after(:all) do
      Chef::Config.configuration = @original_config if @original_config
    end

    after(:each) do
      Chef::Config.configuration = @original_config if @original_config
    end

    it "should not accept a group name or id for group with spaces and multiple backslashes" do
      lambda { @securable.group 'test\ \group' }.should raise_error(ArgumentError)
    end

    it "should accept a unix file mode in string form as an octal number" do
      lambda { @securable.mode "0" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0000" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0111" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "0444" }.should_not raise_error(ArgumentError)

      lambda { @securable.mode "111" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "444" }.should_not raise_error(ArgumentError)
      lambda { @securable.mode "7777" }.should raise_error(ArgumentError)
      lambda { @securable.mode "07777" }.should raise_error(ArgumentError)

      lambda { @securable.mode "-01" }.should raise_error(ArgumentError)
      lambda { @securable.mode "010000" }.should raise_error(ArgumentError)
      lambda { @securable.mode "-1" }.should raise_error(ArgumentError)
      lambda { @securable.mode "10000" }.should raise_error(ArgumentError)

      lambda { @securable.mode "07778" }.should raise_error(ArgumentError)
      lambda { @securable.mode "7778" }.should raise_error(ArgumentError)
      lambda { @securable.mode "4095" }.should raise_error(ArgumentError)

      lambda { @securable.mode "0foo1234" }.should raise_error(ArgumentError)
      lambda { @securable.mode "foo1234" }.should raise_error(ArgumentError)
    end

    it "should accept a unix file mode in numeric form as a ruby-interpreted integer" do
      lambda { @securable.mode 0 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 0000 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 444 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 0444 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 07777 }.should raise_error(ArgumentError)

      lambda { @securable.mode 292 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 4095 }.should raise_error(ArgumentError)

      lambda { @securable.mode 0111 }.should_not raise_error(ArgumentError)
      lambda { @securable.mode 73 }.should_not raise_error(ArgumentError)

      lambda { @securable.mode -01 }.should raise_error(ArgumentError)
      lambda { @securable.mode 010000 }.should raise_error(ArgumentError)
      lambda { @securable.mode -1 }.should raise_error(ArgumentError)
      lambda { @securable.mode 4096 }.should raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write rights" do
      lambda { @securable.rights :full_control, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :modify, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read_execute, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :write, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :to_party, "The Dude" }.should raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write deny_rights" do
      lambda { @securable.deny_rights :full_control, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.deny_rights :modify, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.deny_rights :read_execute, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.deny_rights :read, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.deny_rights :write, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.deny_rights :to_party, "The Dude" }.should raise_error(ArgumentError)
    end

    it "should accept a principal as a string or an array" do
      lambda { @securable.rights :read, "The Dude" }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, ["The Dude","Donny"] }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, 3 }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_children with true/false/:containers_only/:objects_only" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => :containers_only }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => :objects_only }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => 'poop' }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_self with true/false" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_self => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_self => 'poop' }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies one_level_deep with true/false" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => 'poop' }.should raise_error(ArgumentError)
    end

    it "should allow multiple rights and deny_rights declarations" do
      @securable.rights :read, "The Dude"
      @securable.deny_rights :full_control, "The Dude"
      @securable.rights :full_control, "The Dude"
      @securable.rights :write, "The Dude"
      @securable.deny_rights :read, "The Dude"
      @securable.rights.size.should == 3
      @securable.deny_rights.size.should == 2
    end

    it "should allow you to specify whether the permission applies_to_self only if you specified applies_to_children" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => false }.should raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_self => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_self => false }.should_not raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permission applies one_level_deep only if you specified applies_to_children" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => true }.should raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => false }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :one_level_deep => true }.should_not raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :one_level_deep => false }.should_not raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions inherit with true/false" do
      lambda { @securable.inherits true }.should_not raise_error(ArgumentError)
      lambda { @securable.inherits false }.should_not raise_error(ArgumentError)
      lambda { @securable.inherits "monkey" }.should raise_error(ArgumentError)
    end
  end
end
