#
# Author:: Tyler Ball (<tball@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.
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
require 'chef/dsl/audit'
require 'chef/dsl/recipe'
# This includes the Serverspec DSL
require 'chef/audit'

describe "Duplicated `package` DSL in Chef and Serverspec" do
  # This includes the Chef DSL
  include Chef::DSL::Recipe
  # TODO why do I need this?  Should I wrap below in calls to Recipe.instance_eval?
  include Chef::DSL::Audit

  # TODO disable rspec global DSL
  # TODO disable serverspec global DSL

  it "Should call the Chef Recipe DSL in a Chef Recipe" do
    expect(Chef::Resource).to receive(:resource_for_node).with(:package) { Chef::Resource::Package }
    expect(Chef::Resource::Package).to receive(:new).with("foo").and_call_original

    package "foo"
  end

  it "Should call the Serverspec DSL in a `controls` Recipe" do
    #expect(Chef::Resource).to receive(:resource_for_node).with(:package) { Chef::Resource::Package }
    #expect(Chef::Resource::Package).to receive(:new).with("foo").and_call_original

    controls "some controls" do
      package "foo"
    end
  end

end
