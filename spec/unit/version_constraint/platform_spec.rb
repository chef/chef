# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'spec_helper'
require 'chef/version_constraint/platform'

describe Chef::VersionConstraint::Platform do

  it "is a subclass of Chef::VersionConstraint" do
    v = Chef::VersionConstraint::Platform.new
    v.should be_an_instance_of(Chef::VersionConstraint::Platform)
    v.should be_a_kind_of(Chef::VersionConstraint)
  end

  it "should work with Chef::Version::Platform classes" do
    vc = Chef::VersionConstraint::Platform.new("1.0")
    vc.version.should be_an_instance_of(Chef::Version::Platform)
  end

  describe "include?" do

    it "pessimistic ~> x" do
      vc = Chef::VersionConstraint::Platform.new "~> 1"
      vc.should include "1.3.3"
      vc.should include "1.4"

      vc.should_not include "2.2"
      vc.should_not include "0.3.0"
    end

  end
end

