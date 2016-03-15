#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

module TestA
  extend Chef::Mixin::LazyModuleInclude
end

module TestB
  include TestA
  extend Chef::Mixin::LazyModuleInclude
end

class TestC
  include TestB
end

module Monkey
  def monkey
    "monkey"
  end
end

module Klowns
  def klowns
    "klowns"
  end
end

TestA.send(:include, Monkey)

TestB.send(:include, Klowns)

describe Chef::Mixin::LazyModuleInclude do

  it "tracks descendant classes of TestA" do
    expect(TestA.descendants).to include(TestB)
    expect(TestA.descendants).to include(TestC)
  end

  it "tracks descendent classes of TestB" do
    expect(TestB.descendants).to eql([TestC])
  end

  it "including into A mixins in methods into B and C" do
    expect(TestA.instance_methods).to include(:monkey)
    expect(TestB.instance_methods).to include(:monkey)
    expect(TestC.instance_methods).to include(:monkey)
  end

  it "including into B only mixins in methods into C" do
    expect(TestA.instance_methods).not_to include(:klowns)
    expect(TestB.instance_methods).to include(:klowns)
    expect(TestC.instance_methods).to include(:klowns)
  end
end
