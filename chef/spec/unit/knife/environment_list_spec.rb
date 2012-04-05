#
# Author:: Stephen Delano (<stephen@ospcode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Knife::EnvironmentList do
  before(:each) do
    @knife = Chef::Knife::EnvironmentList.new
    @knife.stub!(:msg).and_return true
    @knife.stub!(:output).and_return true
    @knife.stub!(:show_usage).and_return true

    @environments = {
      "production" => "http://localhost:4000/environments/production",
      "development" => "http://localhost:4000/environments/development",
      "testing" => "http://localhost:4000/environments/testing"
    }
    Chef::Environment.stub!(:list).and_return @environments
  end

  it "should make an api call to list the environments" do
    Chef::Environment.should_receive(:list)
    @knife.run
  end

  it "should print the environment names in a sorted list" do
    names = @environments.keys.sort { |a,b| a <=> b }
    @knife.should_receive(:output).with(names)
    @knife.run
  end

  describe "with --with-uri" do
    it "should print and unsorted list of the environments and their URIs" do
      @knife.config[:with_uri] = true
      @knife.should_receive(:output).with(@environments)
      @knife.run
    end
  end
end
