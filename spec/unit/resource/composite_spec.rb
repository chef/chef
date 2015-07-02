#
# Author:: Ranjib Dey (<ranjib@linux.com>)
# Copyright:: Copyright (c) 2015 Ranjib Dey.
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

describe Chef::Resource::Composite do

  before(:each) do
    @resource = Chef::Resource::Composite.new('test_composite')
  end

  it 'has default action as :run' do
    expect(@resource.action).to eql(:run)
  end

  it 'has resource name of :composite' do
    expect(@resource.resource_name).to eql(:composite)
  end

  it "accepts a ruby block for the 'resources' parameter" do
    expect do
      @resource.resources do
        'foo'
      end
    end.to_not raise_error
  end

  it 'returns the block as its identity' do
    expect(@resource.identity).to eq('test_composite')
  end
end
