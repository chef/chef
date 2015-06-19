#
# Author:: Ranjib Dey
# Copyright:: Copyright (c) 2015 Ranjib Dey <ranjib@linux.com>.
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

require 'spec_helper'
require 'chef/resource_resolver'


describe Chef::ResourceResolver do
  it '#resolve' do
    expect(described_class.resolve(:execute)).to eq(Chef::Resource::Execute)
  end

  it '#list' do
    expect(described_class.list(:package)).to_not be_empty
  end

  context 'instance methods' do
    let(:resolver) do
      described_class.new(Chef::Node.new, 'execute[echo]')
    end

    it '#resolve' do
      expect(resolver.resolve).to be_nil
    end

    it '#list' do
      expect(resolver.list).to be_empty
    end

    it '#provided_by?' do
      expect(resolver.provided_by?(Chef::Resource::Execute)).to be_truthy
    end
  end
end
