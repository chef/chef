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

describe Chef::Decorator::LazyArray do
  def foo
    @foo ||= 1
  end

  def bar
    @bar ||= 2
  end

  let(:decorator) do
    Chef::Decorator::LazyArray.new { [ foo, bar ] }
  end

  it "behaves like an array" do
    expect(decorator[0]).to eql(1)
    expect(decorator[1]).to eql(2)
  end

  it "accessing the array elements is lazy" do
    expect(decorator[0].class).to eql(Chef::Decorator::Lazy)
    expect(decorator[1].class).to eql(Chef::Decorator::Lazy)
    expect(@foo).to be nil
    expect(@bar).to be nil
  end

  it "calling a method on the array element runs the proc (and both elements are autovivified)" do
    expect(decorator[0].nil?).to be false
    expect(@foo).to equal(1)
    expect(@bar).to equal(2)
  end

  it "if we loop over the elements and do nothing then its not lazy" do
    # we don't know how many elements there are unless we evaluate the proc
    decorator.each { |i| }
    expect(@foo).to equal(1)
    expect(@bar).to equal(2)
  end
end
