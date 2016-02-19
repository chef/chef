#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::Resource::WindowsService, "initialize" do
  static_provider_resolution(
    resource: Chef::Resource::WindowsService,
    provider: Chef::Provider::Service::Windows,
    os: "windows",
    name: :windows_service,
    action: :start
  )

  let(:resource) { Chef::Resource::WindowsService.new("BITS") }

  it "returns a Chef::Resource::WindowsService" do
    expect(resource).to be_a_kind_of(Chef::Resource::WindowsService)
  end

  it "sets the resource_name to :windows_service" do
    expect(resource.resource_name).to eql(:windows_service)
  end

  it "supports setting startup_type" do
    resource.startup_type(:manual)
    expect(resource.startup_type).to eql(:manual)
  end

  it "allows the action to be 'configure_startup'" do
    resource.action :configure_startup
    expect(resource.action).to eq([:configure_startup])
  end
end
