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
require 'chef/version/platform'

describe Chef::Version::Platform do

  it "is a subclass of Chef::Version" do
    v = Chef::Version::Platform.new('1.1')
    v.should be_an_instance_of(Chef::Version::Platform)
    v.should be_a_kind_of(Chef::Version)
  end

  it "should transform 1 to 1.0.0" do
    Chef::Version::Platform.new("1").to_s.should == "1.0.0"
  end
  
  describe "when creating valid Versions" do
    good_versions = %w(1 1.2 1.2.3 1000.80.50000 0.300.25 001.02.00003)
    good_versions.each do |v|
      it "should accept '#{v}'" do
        Chef::Version::Platform.new v
      end
    end
  end

  describe "when given bogus input" do
    bad_versions = ["1.2.3.4", "1.2.a4", "a", "1.2 3", "1.2 a",
                    "1 2 3", "1-2-3", "1_2_3", "1.2_3", "1.2-3"]
    the_error = Chef::Exceptions::InvalidPlatformVersion
    bad_versions.each do |v|
      it "should raise #{the_error} when given '#{v}'" do
        lambda { Chef::Version::Platform.new v }.should raise_error(the_error)
      end
    end
  end

  describe "<=>" do

    it "should equate versions 1 and 1.0.0" do
      Chef::Version::Platform.new("1").should == Chef::Version::Platform.new("1.0.0")
    end

  end

end

