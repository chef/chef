#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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
require 'chef/version_constraint'

describe Chef::VersionConstraint do
  describe "validation" do
    bad_version = ["> >", ">= 1.2.z", "> 1.2.3 < 5.0", "> 1.2.3, < 5.0"]
    bad_op = ["<3.0.1", ">$ 1.2.3", "! 3.4"]
    o_error = Chef::Exceptions::InvalidVersionConstraint
    v_error = Chef::Exceptions::InvalidCookbookVersion
    bad_version.each do |s|
      it "should raise #{v_error} when given #{s}" do
        lambda { Chef::VersionConstraint.new s }.should raise_error(v_error)
      end
    end
    bad_op.each do |s|
      it "should raise #{o_error} when given #{s}" do
        lambda { Chef::VersionConstraint.new s }.should raise_error(o_error)
      end
    end

    it "should interpret a lone version number as implicit = OP" do
      vc = Chef::VersionConstraint.new("1.2.3")
      vc.to_s.should == "= 1.2.3"
    end

    it "should allow initialization with [] for back compatibility" do
      Chef::VersionConstraint.new([]) == Chef::VersionConstraint.new
    end

    it "should allow initialization with ['1.2.3'] for back compatibility" do
      Chef::VersionConstraint.new(["1.2"]) == Chef::VersionConstraint.new("1.2")
    end

  end

  it "should default to >= 0.0.0" do
    vc = Chef::VersionConstraint.new
    vc.to_s.should == ">= 0.0.0"
  end

  it "should default to >= 0.0.0 when initialized with nil" do
    Chef::VersionConstraint.new(nil).to_s.should == ">= 0.0.0"
  end

  it "should work with Chef::Version classes" do
    vc = Chef::VersionConstraint.new("1.0")
    vc.version.should be_an_instance_of(Chef::Version)
  end

  describe "include?" do
    describe "handles various input data types" do
      before do
        @vc = Chef::VersionConstraint.new "> 1.2.3"
      end
      it "String" do
        @vc.should include "1.4"
      end
      it "Chef::Version" do
        @vc.should include Chef::Version.new("1.4")
      end
      it "Chef::CookbookVersion" do
        cv = Chef::CookbookVersion.new("alice")
        cv.version = "1.4"
        @vc.should include cv
      end
    end

    it "strictly less than" do
      vc = Chef::VersionConstraint.new "< 1.2.3"
      vc.should_not include "1.3.0"
      vc.should_not include "1.2.3"
      vc.should include "1.2.2"
    end

    it "strictly greater than" do
      vc = Chef::VersionConstraint.new "> 1.2.3"
      vc.should include "1.3.0"
      vc.should_not include "1.2.3"
      vc.should_not include "1.2.2"
    end

    it "less than or equal to" do
      vc = Chef::VersionConstraint.new "<= 1.2.3"
      vc.should_not include "1.3.0"
      vc.should include "1.2.3"
      vc.should include "1.2.2"
    end

    it "greater than or equal to" do
      vc = Chef::VersionConstraint.new ">= 1.2.3"
      vc.should include "1.3.0"
      vc.should include "1.2.3"
      vc.should_not include "1.2.2"
    end

    it "equal to" do
      vc = Chef::VersionConstraint.new "= 1.2.3"
      vc.should_not include "1.3.0"
      vc.should include "1.2.3"
      vc.should_not include "0.3.0"
    end

    it "pessimistic ~> x.y.z" do
      vc = Chef::VersionConstraint.new "~> 1.2.3"
      vc.should include "1.2.3"
      vc.should include "1.2.4"

      vc.should_not include "1.2.2"
      vc.should_not include "1.3.0"
      vc.should_not include "2.0.0"
    end

    it "pessimistic ~> x.y" do
      vc = Chef::VersionConstraint.new "~> 1.2"
      vc.should include "1.3.3"
      vc.should include "1.4"

      vc.should_not include "2.2"
      vc.should_not include "0.3.0"
    end
  end
end
