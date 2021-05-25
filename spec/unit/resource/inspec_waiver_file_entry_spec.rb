#
# Author:: Davin Taddeo (<davin@chef.io>)
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

describe Chef::Resource::InspecWaiverFileEntry do
  let(:log_str) { "this is my string to log" }
  let(:resource) { Chef::Resource::InspecWaiverFileEntry.new("fakey_fakerton") }

  it "has a name of inspec_waiver_file_entry" do
    expect(resource.resource_name).to eq(:inspec_waiver_file_entry)
  end

  it "setting the control property to a string does not raise error" do
    expect { resource.control "my_test_control" }.not_to raise_error
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add action" do
    expect { resource.action :add }.not_to raise_error
  end

  it "supports :remove action" do
    expect { resource.action :remove }.not_to raise_error
  end

  it "expects expiration property to fail with date format YYYY/MM/DD" do
    expect { resource.expiration "2022/09/23" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects expiration property to fail with invalid date 2022-02-31" do
    expect { resource.expiration "2022-02-31" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects expiration property to match YYYY-MM-DD" do
    expect { resource.expiration "2022-09-23" }.not_to raise_error
  end

  it "expects the run_test property to fail validation when not a true/false value" do
    expect { resource.run_test "yes" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects the run_test property to only accept true or false values" do
    expect { resource.run_test true }.not_to raise_error
  end

  it "expects the justification property to accept a string value" do
    expect { resource.justification "Because I don't want to run this compliance test" }.not_to raise_error
  end

  it "expects the justification property to fail if given a non-string value" do
    expect { resource.justification true }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects the backup property to fail validation when set to true" do
    expect { resource.backup true }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects the backup property to fail validation when passed a string" do
    expect { resource.backup "please" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end
end
