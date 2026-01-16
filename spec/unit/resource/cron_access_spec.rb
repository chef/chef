#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::CronAccess do
  let(:resource) { Chef::Resource::CronAccess.new("bob") }

  it "has a default action of [:deny]" do
    expect(resource.action).to eql([:allow])
  end

  it "accepts create or delete for action" do
    expect { resource.action :allow }.not_to raise_error
    expect { resource.action :deny }.not_to raise_error
    expect { resource.action :lolcat }.to raise_error(ArgumentError)
  end

  it "the user property is the name_property" do
    expect(resource.user).to eql("bob")
  end
end
