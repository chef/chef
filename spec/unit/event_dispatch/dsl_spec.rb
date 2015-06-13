#
# Author:: Ranjib Dey (<ranjib@linux.com>)
#
# Copyright:: Copyright (c) 2015 Ranjib Dey
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
require 'chef/event_dispatch/dsl'

describe Chef::EventDispatch::DSL do
  subject{ described_class.new }

  it 'raise error when invalid event type is supplied' do
    expect do
      subject.on(:foo_bar) {}
    end.to raise_error(Chef::Exceptions::UnknownEventType)
  end

  it 'register user hooks against valid event type' do
    subject.on(:run_failed) {'testhook'}
    expect(Chef::Config[:event_handlers].first.run_failed).to eq('testhook')
  end
end
