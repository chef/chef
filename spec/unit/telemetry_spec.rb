#
# Author:: Ranjib Dey (<ranjib@linux.com>)
# Copyright:: Copyright (c) 2015 Chef Inc.
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

describe Chef::Telemetry do
  it '#enabled? false by default' do
    expect(subject.enabled?).to be(false)
  end

  context '#publishers' do
    it 'resturns list of publishers if any of them are assigned' do
      Chef::Config.reset!
      expect(Chef::Telemetry.publishers.size).to be(1)
      expect(Chef::Telemetry.publishers.first).to be_kind_of(Chef::Telemetry::Publisher::Log)
    end

    it 'resturns list with only doc publisher if none of them are assigned' do
      fake_publisher = double
      Chef::Config.reset!
      Chef::Config[:telemetry][:publish_using] = [fake_publisher]
      expect(Chef::Telemetry.publishers).to eq([fake_publisher])
    end
  end

  it '#enabled_builtin_metrics' do
    Chef::Config.reset!
    Chef::Config[:telemetry][:resource] = false
    Chef::Config[:telemetry][:recipe] = true
    Chef::Config[:telemetry][:cookbook] = false
    Chef::Config[:telemetry][:gc] = true
    Chef::Config[:telemetry][:process] = false
    Chef::Config[:telemetry][:client_run] = true

    expect(Chef::Telemetry.enabled_builtin_metrics).to eq(%i(recipe gc client_run))
  end
end
