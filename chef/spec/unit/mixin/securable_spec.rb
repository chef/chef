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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

class SecurableTestHarness
  include Chef::Mixin::Securable
  include Chef::Mixin::ParamsValidate
end

describe Chef::Mixin::Securable do

  before do
    @securable = SecurableTestHarness.new
  end

 it "should accept a group name or id for group" do
    lambda { @securable.group "root" }.should_not raise_error(ArgumentError)
    lambda { @securable.group 123 }.should_not raise_error(ArgumentError)
    lambda { @securable.group 'test\ group' }.should_not raise_error(ArgumentError)
    lambda { @securable.group "root*goo" }.should raise_error(ArgumentError)
  end

  it "should accept a unix file mode in string form as an octal number" do
    lambda { @securable.mode "0000" }.should_not raise_error(ArgumentError)
    lambda { @securable.mode "0111" }.should_not raise_error(ArgumentError)
    lambda { @securable.mode "0444" }.should_not raise_error(ArgumentError)

    lambda { @securable.mode "111" }.should_not raise_error(ArgumentError)
    lambda { @securable.mode "444" }.should_not raise_error(ArgumentError)
    lambda { @securable.mode "7777" }.should_not raise_error(ArgumentError)

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
    lambda { @securable.mode 0444 }.should_not raise_error(ArgumentError)
    lambda { @securable.mode 07777 }.should_not raise_error(ArgumentError)

    lambda { @securable.mode 292 }.should_not raise_error(ArgumentError)
    lambda { @securable.mode 4095 }.should_not raise_error(ArgumentError)

    lambda { @securable.mode -01 }.should raise_error(ArgumentError)
    lambda { @securable.mode 010000 }.should raise_error(ArgumentError)
    lambda { @securable.mode -1 }.should raise_error(ArgumentError)
    lambda { @securable.mode 4096 }.should raise_error(ArgumentError)

  end

  it "should only accept a unix file mode with 3 or 4 digits" do
    lambda { @securable.mode 444 }.should_not raise_error(ArgumentError)
    lambda { @securable.mode '444'}.should_not raise_error(ArgumentError)

    # string, equals 5 digits
    lambda { @securable.mode "07777" }.should raise_error(ArgumentError)

    # string, equals 4 digits
    lambda { @securable.mod "7777"}.should_not raise_error(ArgumentError)

    # octal => 5 digts, interpreted as 4 decimal digits, leading zeros do not matter
    lambda { @securable.mode 00666}.should_not raise_error(ArgumentError)
    lambda { @securable.mode 000666}.should_not raise_error(ArgumentError)

    # octal that as decimal is larger than 4 digits (equals 28086 decimal)
    lambda { @securable.mode 066666}.should raise_error(ArgumentError)

    # equals 0 decimal
    lambda { @securable.mode 0000 }.should raise_error(ArgumentError)

    # equals 73 decimal
    lambda { @securable.mode 0111 }.should raise_error(ArgumentError)
    lambda { @securable.mode 73 }.should raise_error(ArgumentError)

    lambda { @securable.mode "0" }.should raise_error(ArgumentError)
    lambda { @securable.mode 0 }.should raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    lambda { @securable.owner "root" }.should_not raise_error(ArgumentError)
    lambda { @securable.owner 123 }.should_not raise_error(ArgumentError)
    lambda { @securable.owner "root*goo" }.should raise_error(ArgumentError)
  end

end
