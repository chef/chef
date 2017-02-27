#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Inc.
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

# This spec file intentionally doesn't include spec_helper.rb to
# be able to test only Chef::Application.
# Regression test for CHEF-5169

require "chef/application"

describe "Chef::Application" do
  let(:app) { Chef::Application.new }

  describe "load_config_file" do
    it "calls ConfigFetcher successfully without NameError" do
      expect { app.load_config_file }.not_to raise_error
    end
  end
end
