#
# Author:: Nimesh Patni (<nimesh.patni@msystechnologies.com>)
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
  let(:provider) { resource.provider_for_action(:update) }

  describe "default:" do
    it "name would be locale" do
      expect(resource.resource_name).to eq(:locale)
    end
    it "lang would be nil" do
      expect(resource.lang).to be_nil
    end
    it "lc_env would be an empty hash" do
      expect(resource.lc_env).to be_a(Hash)
      expect(resource.lc_env).to be_empty
    end
    it "action would be :update" do
      expect(resource.action).to eql([:update])
    end
  end

  describe "validations:" do
    let(:validation) { Chef::Exceptions::ValidationFailed }
    context "lang" do
      it "is non empty" do
        expect { resource.lang("") }.to raise_error(validation)
      end
      it "does not contain any leading whitespaces" do
        expect { resource.lang("  XX") }.to raise_error(validation)
      end
    end

    context "lc_env" do
      it "is non empty" do
        expect { resource.lc_env({ "LC_TIME" => "" }) }.to raise_error(validation)
      end
      it "does not contain any leading whitespaces" do
        expect { resource.lc_env({ "LC_TIME" => " XX" }) }.to raise_error(validation)
      end
      it "keys are valid and case sensitive" do
        expect { resource.lc_env({ "LC_TIMES" => " XX" }) }.to raise_error(validation)
        expect { resource.lc_env({ "Lc_Time" => " XX" }) }.to raise_error(validation)
        expect(resource.lc_env({ "LC_TIME" => "XX" })).to eql({ "LC_TIME" => "XX" })
      end
    end
  end
end
