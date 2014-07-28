#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe 'Chef::Platform#windows_server_2003?' do
  it 'returns false early when not on windows' do
    Chef::Platform.stub(:windows?).and_return(false)
    expect(Chef::Platform).not_to receive(:require)
    expect(Chef::Platform.windows_server_2003?).to be_false
  end

  # CHEF-4888: Need to call WIN32OLE.ole_initialize in new threads
  it 'does not raise an exception' do
    expect { Thread.fork { Chef::Platform.windows_server_2003? }.join }.not_to raise_error
  end
end
