#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::Breakpoint do

  static_provider_resolution(
    resource: Chef::Resource::Breakpoint,
    provider: Chef::Provider::Breakpoint,
    name: :breakpoint,
    action: :break
  )

  before do
    @breakpoint = Chef::Resource::Breakpoint.new
  end

  it "allows the action :break" do
    expect(@breakpoint.allowed_actions).to include(:break)
  end

  it "defaults to the break action" do
    expect(@breakpoint.action).to eq([:break])
  end

  it "names itself after the line number of the file where it's created" do
    expect(@breakpoint.name).to match(/breakpoint_spec\.rb\:[\d]{2}\:in \`new\'$/)
  end

end
