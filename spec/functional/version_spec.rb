#
# Author:: Serdar Sutay (<dan@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require File.expand_path("../../spec_helper", __FILE__)
require "chef/mixin/shell_out"
require "chef/version"
require "ohai/version"

describe "Chef Versions" do
  include Chef::Mixin::ShellOut
  let(:chef_dir) { File.join(File.dirname(__FILE__), "..", "..") }

  binaries = [ "chef-client", "chef-shell", "chef-apply", "knife", "chef-solo" ]

  binaries.each do |binary|
    it "#{binary} version should be sane" do
      expect(shell_out!("ruby #{File.join("bin", binary)} -v", :cwd => chef_dir).stdout.chomp).to include("Chef: #{Chef::VERSION}")
    end
  end

end
