#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

if Chef::Platform.windows? && (not Chef::Platform.windows_server_2003?)
  if !defined? Chef::Win32EventLogLoaded
    if defined? Windows::Constants
      [:INFINITE, :WAIT_FAILED, :FORMAT_MESSAGE_IGNORE_INSERTS, :ERROR_INSUFFICIENT_BUFFER].each do |c|
        # These are redefined in 'win32/eventlog'
        Windows::Constants.send(:remove_const, c) if Windows::Constants.const_defined? c
      end
    end

    require "win32/eventlog"
    Chef::Win32EventLogLoaded = true # rubocop:disable Style/ConstantName
  end
end
