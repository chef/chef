#
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'chef/mixin/deprecation'

describe Chef::Mixin::Deprecation::DeprecatedInstanceVariable do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    @deprecated_ivar = Chef::Mixin::Deprecation::DeprecatedInstanceVariable.new('value', 'an_ivar')
  end

  it "forward method calls to the target object" do
    @deprecated_ivar.length.should == 5
    @deprecated_ivar.to_sym.should == :value
  end

end
