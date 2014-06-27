# encoding: UTF-8
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
    lambda { @securable.group "root" }.should_not raise_error
    lambda { @securable.group 123 }.should_not raise_error
    lambda { @securable.group "+bad:group" }.should raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    lambda { @securable.owner "root" }.should_not raise_error
    lambda { @securable.owner 123 }.should_not raise_error
    lambda { @securable.owner "+bad:owner" }.should raise_error(ArgumentError)
  end

  it "allows the owner to be specified as #user" do
    @securable.should respond_to(:user)
  end

  describe "unix-specific behavior" do
    before(:each) do
      platform_mock :unix do
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "mixin", "securable.rb")
        @securable = Object.new
        @securable.send(:extend, Chef::Mixin::Securable)
        @securable.send(:extend, Chef::Mixin::ParamsValidate)
      end
    end

    it "should accept group/owner names with spaces and backslashes" do
      lambda { @securable.group 'test\ group' }.should_not raise_error
      lambda { @securable.owner 'test\ group' }.should_not raise_error
    end

    it "should accept group/owner names that are a single character or digit" do
      lambda { @securable.group 'v' }.should_not raise_error
      lambda { @securable.group '1' }.should_not raise_error
      lambda { @securable.owner 'v' }.should_not raise_error
      lambda { @securable.owner '1' }.should_not raise_error
    end

    it "should not accept group/owner names starting with '-', '+', or '~'" do
      lambda { @securable.group '-test' }.should raise_error(ArgumentError)
      lambda { @securable.group '+test' }.should raise_error(ArgumentError)
      lambda { @securable.group '~test' }.should raise_error(ArgumentError)
      lambda { @securable.group 'te-st' }.should_not raise_error
      lambda { @securable.group 'te+st' }.should_not raise_error
      lambda { @securable.group 'te~st' }.should_not raise_error
      lambda { @securable.owner '-test' }.should raise_error(ArgumentError)
      lambda { @securable.owner '+test' }.should raise_error(ArgumentError)
      lambda { @securable.owner '~test' }.should raise_error(ArgumentError)
      lambda { @securable.owner 'te-st' }.should_not raise_error
      lambda { @securable.owner 'te+st' }.should_not raise_error
      lambda { @securable.owner 'te~st' }.should_not raise_error
    end

    it "should not accept group/owner names containing ':', ',' or non-space whitespace" do
      lambda { @securable.group ':test' }.should raise_error(ArgumentError)
      lambda { @securable.group 'te:st' }.should raise_error(ArgumentError)
      lambda { @securable.group ',test' }.should raise_error(ArgumentError)
      lambda { @securable.group 'te,st' }.should raise_error(ArgumentError)
      lambda { @securable.group "\ttest" }.should raise_error(ArgumentError)
      lambda { @securable.group "te\tst" }.should raise_error(ArgumentError)
      lambda { @securable.group "\rtest" }.should raise_error(ArgumentError)
      lambda { @securable.group "te\rst" }.should raise_error(ArgumentError)
      lambda { @securable.group "\ftest" }.should raise_error(ArgumentError)
      lambda { @securable.group "te\fst" }.should raise_error(ArgumentError)
      lambda { @securable.group "\0test" }.should raise_error(ArgumentError)
      lambda { @securable.group "te\0st" }.should raise_error(ArgumentError)
      lambda { @securable.owner ':test' }.should raise_error(ArgumentError)
      lambda { @securable.owner 'te:st' }.should raise_error(ArgumentError)
      lambda { @securable.owner ',test' }.should raise_error(ArgumentError)
      lambda { @securable.owner 'te,st' }.should raise_error(ArgumentError)
      lambda { @securable.owner "\ttest" }.should raise_error(ArgumentError)
      lambda { @securable.owner "te\tst" }.should raise_error(ArgumentError)
      lambda { @securable.owner "\rtest" }.should raise_error(ArgumentError)
      lambda { @securable.owner "te\rst" }.should raise_error(ArgumentError)
      lambda { @securable.owner "\ftest" }.should raise_error(ArgumentError)
      lambda { @securable.owner "te\fst" }.should raise_error(ArgumentError)
      lambda { @securable.owner "\0test" }.should raise_error(ArgumentError)
      lambda { @securable.owner "te\0st" }.should raise_error(ArgumentError)
    end

    it "should accept Active Directory-style domain names pulled in via LDAP (on unix hosts)" do
      lambda { @securable.owner "domain\@user" }.should_not raise_error
      lambda { @securable.owner "domain\\user" }.should_not raise_error
      lambda { @securable.group "domain\@group" }.should_not raise_error
      lambda { @securable.group "domain\\group" }.should_not raise_error
      lambda { @securable.group "domain\\group^name" }.should_not raise_error
    end

    it "should not accept group/owner names containing embedded carriage returns" do
      pending "XXX: params_validate needs to be extended to support multi-line regex"
      #lambda { @securable.group "\ntest" }.should raise_error(ArgumentError)
      #lambda { @securable.group "te\nst" }.should raise_error(ArgumentError)
      #lambda { @securable.owner "\ntest" }.should raise_error(ArgumentError)
      #lambda { @securable.owner "te\nst" }.should raise_error(ArgumentError)
    end

    it "should accept group/owner names in UTF-8" do
      lambda { @securable.group 'tëst' }.should_not raise_error
      lambda { @securable.group 'ë' }.should_not raise_error
      lambda { @securable.owner 'tëst' }.should_not raise_error
      lambda { @securable.owner 'ë' }.should_not raise_error
    end

    it "should accept a unix file mode in string form as an octal number" do
      lambda { @securable.mode "0" }.should_not raise_error
      lambda { @securable.mode "0000" }.should_not raise_error
      lambda { @securable.mode "0111" }.should_not raise_error
      lambda { @securable.mode "0444" }.should_not raise_error

      lambda { @securable.mode "111" }.should_not raise_error
      lambda { @securable.mode "444" }.should_not raise_error
      lambda { @securable.mode "7777" }.should_not raise_error
      lambda { @securable.mode "07777" }.should_not raise_error

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
      lambda { @securable.mode(0) }.should_not raise_error
      lambda { @securable.mode(0000) }.should_not raise_error
      lambda { @securable.mode(444) }.should_not raise_error
      lambda { @securable.mode(0444) }.should_not raise_error
      lambda { @securable.mode(07777) }.should_not raise_error

      lambda { @securable.mode(292) }.should_not raise_error
      lambda { @securable.mode(4095) }.should_not raise_error

      lambda { @securable.mode(0111) }.should_not raise_error
      lambda { @securable.mode(73) }.should_not raise_error

      lambda { @securable.mode(-01) }.should raise_error(ArgumentError)
      lambda { @securable.mode(010000) }.should raise_error(ArgumentError)
      lambda { @securable.mode(-1) }.should raise_error(ArgumentError)
      lambda { @securable.mode(4096) }.should raise_error(ArgumentError)
    end
  end

  describe "windows-specific behavior" do
    before(:each) do
      platform_mock :windows do
        load File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "chef", "mixin", "securable.rb")
        securable_class = Class.new do
          include Chef::Mixin::Securable
          include Chef::Mixin::ParamsValidate
        end
        @securable = securable_class.new
      end
    end

    it "should not accept a group name or id for group with spaces and multiple backslashes" do
      lambda { @securable.group 'test\ \group' }.should raise_error(ArgumentError)
    end

    it "should accept a unix file mode in string form as an octal number" do
      lambda { @securable.mode "0" }.should_not raise_error
      lambda { @securable.mode "0000" }.should_not raise_error
      lambda { @securable.mode "0111" }.should_not raise_error
      lambda { @securable.mode "0444" }.should_not raise_error

      lambda { @securable.mode "111" }.should_not raise_error
      lambda { @securable.mode "444" }.should_not raise_error
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
      lambda { @securable.mode 0 }.should_not raise_error
      lambda { @securable.mode 0000 }.should_not raise_error
      lambda { @securable.mode 444 }.should_not raise_error
      lambda { @securable.mode 0444 }.should_not raise_error
      lambda { @securable.mode 07777 }.should raise_error(ArgumentError)

      lambda { @securable.mode 292 }.should_not raise_error
      lambda { @securable.mode 4095 }.should raise_error(ArgumentError)

      lambda { @securable.mode 0111 }.should_not raise_error
      lambda { @securable.mode 73 }.should_not raise_error

      lambda { @securable.mode -01 }.should raise_error(ArgumentError)
      lambda { @securable.mode 010000 }.should raise_error(ArgumentError)
      lambda { @securable.mode -1 }.should raise_error(ArgumentError)
      lambda { @securable.mode 4096 }.should raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write rights" do
      lambda { @securable.rights :full_control, "The Dude" }.should_not raise_error
      lambda { @securable.rights :modify, "The Dude" }.should_not raise_error
      lambda { @securable.rights :read_execute, "The Dude" }.should_not raise_error
      lambda { @securable.rights :read, "The Dude" }.should_not raise_error
      lambda { @securable.rights :write, "The Dude" }.should_not raise_error
      lambda { @securable.rights :to_party, "The Dude" }.should raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write deny_rights" do
      lambda { @securable.deny_rights :full_control, "The Dude" }.should_not raise_error
      lambda { @securable.deny_rights :modify, "The Dude" }.should_not raise_error
      lambda { @securable.deny_rights :read_execute, "The Dude" }.should_not raise_error
      lambda { @securable.deny_rights :read, "The Dude" }.should_not raise_error
      lambda { @securable.deny_rights :write, "The Dude" }.should_not raise_error
      lambda { @securable.deny_rights :to_party, "The Dude" }.should raise_error(ArgumentError)
    end

    it "should accept a principal as a string or an array" do
      lambda { @securable.rights :read, "The Dude" }.should_not raise_error
      lambda { @securable.rights :read, ["The Dude","Donny"] }.should_not raise_error
      lambda { @securable.rights :read, 3 }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_children with true/false/:containers_only/:objects_only" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => :containers_only }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => :objects_only }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => 'poop' }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_self with true/false" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_self => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_self => 'poop' }.should raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies one_level_deep with true/false" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.should_not raise_error
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
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => false }.should raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_self => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_self => false }.should_not raise_error
    end

    it "should allow you to specify whether the permission applies one_level_deep only if you specified applies_to_children" do
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => true }.should raise_error(ArgumentError)
      lambda { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => false }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :one_level_deep => true }.should_not raise_error
      lambda { @securable.rights :read, "The Dude", :one_level_deep => false }.should_not raise_error
    end

    it "should allow you to specify whether the permissions inherit with true/false" do
      lambda { @securable.inherits true }.should_not raise_error
      lambda { @securable.inherits false }.should_not raise_error
      lambda { @securable.inherits "monkey" }.should raise_error(ArgumentError)
    end
  end
end
