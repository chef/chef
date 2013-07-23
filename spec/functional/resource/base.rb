#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

def ohai
  # provider is platform-dependent, we need platform ohai data:
  @OHAI_SYSTEM ||= begin
    ohai = Ohai::System.new
    ohai.require_plugin("os")
    ohai.require_plugin("platform")
    ohai.require_plugin("passwd")
    ohai
  end
end

def run_context
  @run_context ||= begin
    node = Chef::Node.new
    node.default[:platform] = ohai[:platform]
    node.default[:platform_version] = ohai[:platform_version]
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end
end
