#
# Author:: Serdar Sutay (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path('../../spec_helper', __FILE__)
require 'chef/mixin/shell_out'
require 'chef/version'
require 'ohai/version'

describe "Chef Versions" do
  include Chef::Mixin::ShellOut

  it "chef-client version should be sane" do
    shell_out("bundle exec chef-client -v").stdout.chomp.should == "Chef: #{Chef::VERSION}"
  end

  it "chef-shell version should be sane" do
    shell_out("bundle exec chef-shell -v").stdout.chomp.should == "Chef: #{Chef::VERSION}"
  end

  it "knife version should be sane" do
    shell_out("bundle exec knife -v").stdout.chomp.should == "Chef: #{Chef::VERSION}"
  end

  it "ohai version should be sane" do
    shell_out("bundle exec ohai -v").stdout.chomp.should == "Ohai: #{Ohai::VERSION}"
  end
end
