#
# Author:: Ranjib Dey <ranjib@linux.com>
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

describe Chef::Telemetry::Processor do
  let(:processor) do
    described_class.new
  end

  let(:publisher) do
    double
  end

  it '#initialize' do
    expect(processor.metrics).to be_empty
    expect(processor.publishers).to be_empty
  end

  it '#add_metric' do
    processor.add_metric('foo'){}
    expect(processor.metrics.first.name).to eq('foo')
  end

  it '#add_publisher' do
    processor.add_publisher(publisher)
    expect(processor.publishers.first).to eq(publisher)
  end

  it '#gather' do
    processor.add_metric 'foo' do
      'bar'
    end
    processor.gather
    expect(processor.metrics.first.value).to eq('bar')
  end

  it '#publish' do
    processor.add_metric 'foo' do
      'bar'
    end
    processor.add_publisher(publisher)
    processor.gather
    expect(publisher).to receive(:publish)
    processor.publish
  end

  it '#create' do
    p = described_class.create([publisher])
    expect(p.publishers.first).to eq(publisher)
  end
end
