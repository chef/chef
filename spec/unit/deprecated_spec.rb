#
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
#

require "spec_helper"
require "chef/deprecated"

describe Chef::Deprecated do
  class TestDeprecation < Chef::Deprecated::Base
    def id; 999; end

    def target; "test.html"; end

    def link; "#{Chef::Deprecated::Base::BASE_URL}test.html"; end
  end

  context "loading a deprecation class" do
    it "loads the correct class" do
      expect(Chef::Deprecated.create(:test_deprecation)).to be_an_instance_of(Chef::Deprecated::TestDeprecation)
    end

    it "optionally sets a message" do
      deprecation = Chef::Deprecated.create(:test_deprecation, "A test message")
      expect(deprecation.message).to eql("A test message")
    end

    it "optionally sets the location" do
      deprecation = Chef::Deprecated.create(:test_deprecation, nil, "A test location")
      expect(deprecation.location).to eql("A test location")
    end
  end

  context "formatting deprecation warnings" do
    let(:base_url) { Chef::Deprecated::Base::BASE_URL }
    let(:message) { "A test message" }
    let(:location) { "the location" }

    it "displays the full URL" do
      expect(Chef::Deprecated::TestDeprecation.new().url).to eql("#{base_url}test.html")
    end

    it "formats a complete deprecation message" do
      expect(Chef::Deprecated::TestDeprecation.new(message, location).inspect).to eql("#{message} (CHEF-999)#{location}.\nhttps://docs.chef.io/deprecations_test.html")
    end
  end
end
