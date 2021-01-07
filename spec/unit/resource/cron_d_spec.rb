#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::CronD do
  let(:resource) { Chef::Resource::CronD.new("cronify") }

  it "has a default action of [:create]" do
    expect(resource.action).to eql([:create])
  end

  it "accepts create or delete for action" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :lolcat }.to raise_error(ArgumentError)
  end

  it "the cron_name property is the name_property" do
    expect(resource.cron_name).to eql("cronify")
  end

  it "the mode property defaults to '0600'" do
    expect(resource.mode).to eql("0600")
  end

  it "the user property defaults to 'root'" do
    expect(resource.user).to eql("root")
  end

  it "the command property is required" do
    expect { resource.command nil }.to raise_error(Chef::Exceptions::ValidationFailed)
  end
end
