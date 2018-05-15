#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

describe Chef::Decorator::Lazy do
  let(:decorator) do
    @a = 0
    Chef::Decorator::Lazy.new { @a += 1 }
  end

  it "decorates an object" do
    expect(decorator.even?).to be false
  end

  it "the proc runs and does work" do
    expect(decorator).to eql(1)
  end

  it "creating the decorator does not cause the proc to run" do
    decorator
    expect(@a).to eql(0)
  end
end
