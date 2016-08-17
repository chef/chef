#
# Author:: Daniel DeLeo (<dan@chef.io>)
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
require "chef/mixin/deprecation"

describe Chef::Mixin do
  describe "deprecating constants (Class/Module)" do
    before do
      Chef::Mixin.deprecate_constant(:DeprecatedClass, Chef::Node, "This is a test deprecation")
      @log_io = StringIO.new
      Chef::Log.init(@log_io)
    end

    it "has a list of deprecated constants" do
      expect(Chef::Mixin.deprecated_constants).to have_key(:DeprecatedClass)
    end

    it "returns the replacement when accessing the deprecated constant" do
      expect(Chef::Mixin::DeprecatedClass).to eq(Chef::Node)
    end

    it "warns when accessing the deprecated constant" do
      Chef::Mixin::DeprecatedClass # rubocop:disable Lint/Void
      expect(@log_io.string).to include("This is a test deprecation")
    end
  end
end

describe Chef::Mixin::Deprecation::DeprecatedInstanceVariable do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    @deprecated_ivar = Chef::Mixin::Deprecation::DeprecatedInstanceVariable.new("value", "an_ivar")
  end

  it "forward method calls to the target object" do
    expect(@deprecated_ivar.length).to eq(5)
    expect(@deprecated_ivar.to_sym).to eq(:value)
  end

end
