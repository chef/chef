#
# Author:: Vincent AUBERT (<vincentaubert88@gmail.com>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

describe Chef::Resource::Locale do

  let(:resource) { Chef::Resource::Locale.new("fakey_fakerton") }

  it "has a name of locale" do
    expect(resource.resource_name).to eq(:locale)
  end

  it "the lang property is equal to en_US.utf8" do
    expect(resource.lang).to eql("en_US.utf8")
  end

  it "the lc_all property is equal to en_US.utf8" do
    expect(resource.lc_all).to eql("en_US.utf8")
  end

  it "sets the default action as :update" do
    expect(resource.action).to eql([:update])
  end

  it "supports :update action" do
    expect { resource.action :update }.not_to raise_error
  end

  describe "when the language is not the default one" do
    let(:resource) { Chef::Resource::Locale.new("fakey_fakerton") }
    before do
      resource.lang("fr_FR.utf8")
      resource.lc_all("fr_FR.utf8")
    end

    it "the lang property is equal to fr_FR.utf8" do
      expect(resource.lang).to eql("fr_FR.utf8")
    end

    it "the lc_all property is equal to fr_FR.utf8" do
      expect(resource.lc_all).to eql("fr_FR.utf8")
    end
  end
end
