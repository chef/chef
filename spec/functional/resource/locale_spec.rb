#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
# Copyright: Copyright 2008-2018, Chef Software, Inc.
# License: Apache License, Version 2.0
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
require "functional/resource/base"

describe Chef::Resource::Locale, :unix_only do
  let(:locale_obj) { Chef::Resource::Locale.new("foo_resource", run_context) }
  describe "when user pass lang and lc_all" do
    let(:resource) do
      resource = locale_obj
      resource.lang("en_GB.utf8")
      resource.lc_all("en_GB.utf8")
      resource
    end

    it "when the lang and lc_all is not the same as current locale values" do
      resource.run_action(:update)
      expect(resource).to be_updated_by_last_action
    end

    it "when the lang and lc_all is the same as current locale values" do
      resource.run_action(:update)
      expect(resource).not_to be_updated_by_last_action
    end
  end

  describe "when user pass only lang" do
    let(:resource) do
      resource = locale_obj
      resource.lang("en_US.utf8")
      resource
    end
    it "when the lang is not the same as current locale values" do
      resource.run_action(:update)
      expect(resource).to be_updated_by_last_action
    end

    it "when the lang is the same as current locale values" do
      resource.run_action(:update)
      expect(resource).not_to be_updated_by_last_action
    end
  end

  describe "when user pass only lc_all" do
    let(:resource) do
      resource = locale_obj
      resource.lc_all("en_US.utf8")
      resource
    end
    it "when the lc_all is not the same as current locale values" do
      resource.run_action(:update)
      expect(resource).to be_updated_by_last_action
    end

    it "when the lc_all is the same as current locale values" do
      resource.run_action(:update)
      expect(resource).not_to be_updated_by_last_action
    end
  end
end
