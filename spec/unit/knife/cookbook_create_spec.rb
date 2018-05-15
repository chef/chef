#
# Author:: Nuo Yan (<nuo@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
require "tmpdir"

describe Chef::Knife::CookbookCreate do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    Chef::Config[:treat_deprecation_warnings_as_errors] = false
    @knife = Chef::Knife::CookbookCreate.new
    @knife.config = {}
    @knife.name_args = ["foobar"]
    @stdout = StringIO.new
    allow(@knife).to receive(:stdout).and_return(@stdout)
  end

  describe "run" do

    # Fixes CHEF-2579
    it "should expand the path of the cookbook directory" do
      expect(Chef::Log).to receive(:fatal).with("knife cookbook create has been removed. Please use `chef generate cookbook` from the ChefDK")
      @knife.run
    end

  end
end
