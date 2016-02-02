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

class SubclassDirectiveParent
  extend Chef::Mixin::SubclassDirective

  subclass_directive :behave_differently
end

class SubclassDirectiveChild < SubclassDirectiveParent
  behave_differently
end

class ChildWithoutDirective < SubclassDirectiveParent
end

describe Chef::Mixin::Uris do
  let (:child) { SubclassDirectiveChild.new }

  let (:other_child) { ChildWithoutDirective.new }

  it "the child instance has the directive set" do
    expect(child.behave_differently?).to be true
  end

  it "a child that does not declare it does not have it set" do
    expect(other_child.behave_differently?).to be false
  end
end
