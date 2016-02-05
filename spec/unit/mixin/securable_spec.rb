# encoding: UTF-8
#
# Author:: Mark Mzyk (<mmzyk@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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

describe Chef::Mixin::Securable do

  before(:each) do
    @securable = Object.new
    @securable.send(:extend, Chef::Mixin::Securable)
    @securable.send(:extend, Chef::Mixin::ParamsValidate)
  end

  it "should accept a group name or id for group" do
    expect { @securable.group "root" }.not_to raise_error
    expect { @securable.group 123 }.not_to raise_error
    expect { @securable.group "+bad:group" }.to raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    expect { @securable.owner "root" }.not_to raise_error
    expect { @securable.owner 123 }.not_to raise_error
    expect { @securable.owner "+bad:owner" }.to raise_error(ArgumentError)
  end

  it "allows the owner to be specified as #user" do
    expect(@securable).to respond_to(:user)
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
      expect { @securable.group 'test\ group' }.not_to raise_error
      expect { @securable.owner 'test\ group' }.not_to raise_error
    end

    it "should accept group/owner names that are a single character or digit" do
      expect { @securable.group "v" }.not_to raise_error
      expect { @securable.group "1" }.not_to raise_error
      expect { @securable.owner "v" }.not_to raise_error
      expect { @securable.owner "1" }.not_to raise_error
    end

    it "should not accept group/owner names starting with '-', '+', or '~'" do
      expect { @securable.group "-test" }.to raise_error(ArgumentError)
      expect { @securable.group "+test" }.to raise_error(ArgumentError)
      expect { @securable.group "~test" }.to raise_error(ArgumentError)
      expect { @securable.group "te-st" }.not_to raise_error
      expect { @securable.group "te+st" }.not_to raise_error
      expect { @securable.group "te~st" }.not_to raise_error
      expect { @securable.owner "-test" }.to raise_error(ArgumentError)
      expect { @securable.owner "+test" }.to raise_error(ArgumentError)
      expect { @securable.owner "~test" }.to raise_error(ArgumentError)
      expect { @securable.owner "te-st" }.not_to raise_error
      expect { @securable.owner "te+st" }.not_to raise_error
      expect { @securable.owner "te~st" }.not_to raise_error
    end

    it "should not accept group/owner names containing ':', ',' or non-space whitespace" do
      expect { @securable.group ":test" }.to raise_error(ArgumentError)
      expect { @securable.group "te:st" }.to raise_error(ArgumentError)
      expect { @securable.group ",test" }.to raise_error(ArgumentError)
      expect { @securable.group "te,st" }.to raise_error(ArgumentError)
      expect { @securable.group "\ttest" }.to raise_error(ArgumentError)
      expect { @securable.group "te\tst" }.to raise_error(ArgumentError)
      expect { @securable.group "\rtest" }.to raise_error(ArgumentError)
      expect { @securable.group "te\rst" }.to raise_error(ArgumentError)
      expect { @securable.group "\ftest" }.to raise_error(ArgumentError)
      expect { @securable.group "te\fst" }.to raise_error(ArgumentError)
      expect { @securable.group "\0test" }.to raise_error(ArgumentError)
      expect { @securable.group "te\0st" }.to raise_error(ArgumentError)
      expect { @securable.owner ":test" }.to raise_error(ArgumentError)
      expect { @securable.owner "te:st" }.to raise_error(ArgumentError)
      expect { @securable.owner ",test" }.to raise_error(ArgumentError)
      expect { @securable.owner "te,st" }.to raise_error(ArgumentError)
      expect { @securable.owner "\ttest" }.to raise_error(ArgumentError)
      expect { @securable.owner "te\tst" }.to raise_error(ArgumentError)
      expect { @securable.owner "\rtest" }.to raise_error(ArgumentError)
      expect { @securable.owner "te\rst" }.to raise_error(ArgumentError)
      expect { @securable.owner "\ftest" }.to raise_error(ArgumentError)
      expect { @securable.owner "te\fst" }.to raise_error(ArgumentError)
      expect { @securable.owner "\0test" }.to raise_error(ArgumentError)
      expect { @securable.owner "te\0st" }.to raise_error(ArgumentError)
    end

    it "should accept Active Directory-style domain names pulled in via LDAP (on unix hosts)" do
      expect { @securable.owner "domain\@user" }.not_to raise_error
      expect { @securable.owner "domain\\user" }.not_to raise_error
      expect { @securable.group "domain\@group" }.not_to raise_error
      expect { @securable.group "domain\\group" }.not_to raise_error
      expect { @securable.group "domain\\group^name" }.not_to raise_error
    end

    it "should not accept group/owner names containing embedded carriage returns" do
      skip "XXX: params_validate needs to be extended to support multi-line regex"
      #lambda { @securable.group "\ntest" }.should raise_error(ArgumentError)
      #lambda { @securable.group "te\nst" }.should raise_error(ArgumentError)
      #lambda { @securable.owner "\ntest" }.should raise_error(ArgumentError)
      #lambda { @securable.owner "te\nst" }.should raise_error(ArgumentError)
    end

    it "should accept group/owner names in UTF-8" do
      expect { @securable.group "tëst" }.not_to raise_error
      expect { @securable.group "ë" }.not_to raise_error
      expect { @securable.owner "tëst" }.not_to raise_error
      expect { @securable.owner "ë" }.not_to raise_error
    end

    it "should accept a unix file mode in string form as an octal number" do
      expect { @securable.mode "0" }.not_to raise_error
      expect { @securable.mode "0000" }.not_to raise_error
      expect { @securable.mode "0111" }.not_to raise_error
      expect { @securable.mode "0444" }.not_to raise_error

      expect { @securable.mode "111" }.not_to raise_error
      expect { @securable.mode "444" }.not_to raise_error
      expect { @securable.mode "7777" }.not_to raise_error
      expect { @securable.mode "07777" }.not_to raise_error

      expect { @securable.mode "-01" }.to raise_error(ArgumentError)
      expect { @securable.mode "010000" }.to raise_error(ArgumentError)
      expect { @securable.mode "-1" }.to raise_error(ArgumentError)
      expect { @securable.mode "10000" }.to raise_error(ArgumentError)

      expect { @securable.mode "07778" }.to raise_error(ArgumentError)
      expect { @securable.mode "7778" }.to raise_error(ArgumentError)
      expect { @securable.mode "4095" }.to raise_error(ArgumentError)

      expect { @securable.mode "0foo1234" }.to raise_error(ArgumentError)
      expect { @securable.mode "foo1234" }.to raise_error(ArgumentError)
    end

    it "should accept a unix file mode in numeric form as a ruby-interpreted integer" do
      expect { @securable.mode(0) }.not_to raise_error
      expect { @securable.mode(0000) }.not_to raise_error
      expect { @securable.mode(444) }.not_to raise_error
      expect { @securable.mode(0444) }.not_to raise_error
      expect { @securable.mode(07777) }.not_to raise_error

      expect { @securable.mode(292) }.not_to raise_error
      expect { @securable.mode(4095) }.not_to raise_error

      expect { @securable.mode(0111) }.not_to raise_error
      expect { @securable.mode(73) }.not_to raise_error

      expect { @securable.mode(-01) }.to raise_error(ArgumentError)
      expect { @securable.mode(010000) }.to raise_error(ArgumentError)
      expect { @securable.mode(-1) }.to raise_error(ArgumentError)
      expect { @securable.mode(4096) }.to raise_error(ArgumentError)
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
      expect { @securable.group 'test\ \group' }.to raise_error(ArgumentError)
    end

    it "should accept a unix file mode in string form as an octal number" do
      expect { @securable.mode "0" }.not_to raise_error
      expect { @securable.mode "0000" }.not_to raise_error
      expect { @securable.mode "0111" }.not_to raise_error
      expect { @securable.mode "0444" }.not_to raise_error

      expect { @securable.mode "111" }.not_to raise_error
      expect { @securable.mode "444" }.not_to raise_error
      expect { @securable.mode "7777" }.to raise_error(ArgumentError)
      expect { @securable.mode "07777" }.to raise_error(ArgumentError)

      expect { @securable.mode "-01" }.to raise_error(ArgumentError)
      expect { @securable.mode "010000" }.to raise_error(ArgumentError)
      expect { @securable.mode "-1" }.to raise_error(ArgumentError)
      expect { @securable.mode "10000" }.to raise_error(ArgumentError)

      expect { @securable.mode "07778" }.to raise_error(ArgumentError)
      expect { @securable.mode "7778" }.to raise_error(ArgumentError)
      expect { @securable.mode "4095" }.to raise_error(ArgumentError)

      expect { @securable.mode "0foo1234" }.to raise_error(ArgumentError)
      expect { @securable.mode "foo1234" }.to raise_error(ArgumentError)
    end

    it "should accept a unix file mode in numeric form as a ruby-interpreted integer" do
      expect { @securable.mode 0 }.not_to raise_error
      expect { @securable.mode 0000 }.not_to raise_error
      expect { @securable.mode 444 }.not_to raise_error
      expect { @securable.mode 0444 }.not_to raise_error
      expect { @securable.mode 07777 }.to raise_error(ArgumentError)

      expect { @securable.mode 292 }.not_to raise_error
      expect { @securable.mode 4095 }.to raise_error(ArgumentError)

      expect { @securable.mode 0111 }.not_to raise_error
      expect { @securable.mode 73 }.not_to raise_error

      expect { @securable.mode(-01) }.to raise_error(ArgumentError)
      expect { @securable.mode 010000 }.to raise_error(ArgumentError)
      expect { @securable.mode(-1) }.to raise_error(ArgumentError)
      expect { @securable.mode 4096 }.to raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write rights" do
      expect { @securable.rights :full_control, "The Dude" }.not_to raise_error
      expect { @securable.rights :modify, "The Dude" }.not_to raise_error
      expect { @securable.rights :read_execute, "The Dude" }.not_to raise_error
      expect { @securable.rights :read, "The Dude" }.not_to raise_error
      expect { @securable.rights :write, "The Dude" }.not_to raise_error
      expect { @securable.rights :to_party, "The Dude" }.to raise_error(ArgumentError)
    end

    it "should allow you to specify :full_control, :modify, :read_execute, :read, and :write deny_rights" do
      expect { @securable.deny_rights :full_control, "The Dude" }.not_to raise_error
      expect { @securable.deny_rights :modify, "The Dude" }.not_to raise_error
      expect { @securable.deny_rights :read_execute, "The Dude" }.not_to raise_error
      expect { @securable.deny_rights :read, "The Dude" }.not_to raise_error
      expect { @securable.deny_rights :write, "The Dude" }.not_to raise_error
      expect { @securable.deny_rights :to_party, "The Dude" }.to raise_error(ArgumentError)
    end

    it "should accept a principal as a string or an array" do
      expect { @securable.rights :read, "The Dude" }.not_to raise_error
      expect { @securable.rights :read, ["The Dude", "Donny"] }.not_to raise_error
      expect { @securable.rights :read, 3 }.to raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_children with true/false/:containers_only/:objects_only" do
      expect { @securable.rights :read, "The Dude", :applies_to_children => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => :containers_only }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => :objects_only }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => "poop" }.to raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies_to_self with true/false" do
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_self => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_self => "poop" }.to raise_error(ArgumentError)
    end

    it "should allow you to specify whether the permissions applies one_level_deep with true/false" do
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => "poop" }.to raise_error(ArgumentError)
    end

    it "should allow multiple rights and deny_rights declarations" do
      @securable.rights :read, "The Dude"
      @securable.deny_rights :full_control, "The Dude"
      @securable.rights :full_control, "The Dude"
      @securable.rights :write, "The Dude"
      @securable.deny_rights :read, "The Dude"
      expect(@securable.rights.size).to eq(3)
      expect(@securable.deny_rights.size).to eq(2)
    end

    it "should allow you to specify whether the permission applies_to_self only if you specified applies_to_children" do
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :applies_to_self => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => false, :applies_to_self => false }.to raise_error(ArgumentError)
      expect { @securable.rights :read, "The Dude", :applies_to_self => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_self => false }.not_to raise_error
    end

    it "should allow you to specify whether the permission applies one_level_deep only if you specified applies_to_children" do
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => true, :one_level_deep => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => true }.to raise_error(ArgumentError)
      expect { @securable.rights :read, "The Dude", :applies_to_children => false, :one_level_deep => false }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :one_level_deep => true }.not_to raise_error
      expect { @securable.rights :read, "The Dude", :one_level_deep => false }.not_to raise_error
    end

    it "should allow you to specify whether the permissions inherit with true/false" do
      expect { @securable.inherits true }.not_to raise_error
      expect { @securable.inherits false }.not_to raise_error
      expect { @securable.inherits "monkey" }.to raise_error(ArgumentError)
    end
  end
end
