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

describe Chef::Resource::CronD do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::CronD.new("cronify", run_context) }
  let(:provider) { resource.provider_for_action(:create) }

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

  context "on linux" do
    before(:each) do
      node.automatic_attrs[:os] = "linux"
    end

    it "the cron_name property is valid" do
      provider.define_resource_requirements

      expect { resource.cron_name "cron-job";   provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "cron_job_0"; provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "CronJob";    provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "cron!";      provider.process_resource_requirements }.to raise_error "The cron job name should contain letters, numbers, hyphens and underscores only."
      expect { resource.cron_name "cron job";   provider.process_resource_requirements }.to raise_error "The cron job name should contain letters, numbers, hyphens and underscores only."
    end
  end

  context "not on linux" do
    before(:each) do
      node.automatic_attrs[:os] = "aix"
    end

    it "all cron names are valid" do
      provider.define_resource_requirements

      expect { resource.cron_name "cron-job";   provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "cron_job_0"; provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "CronJob";    provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "cron!";      provider.process_resource_requirements }.not_to raise_error
      expect { resource.cron_name "cron job";   provider.process_resource_requirements }.not_to raise_error
    end
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
