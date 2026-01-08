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

describe Chef::Resource::WindowsFeature do
  let(:resource) { Chef::Resource::WindowsFeature.new("fakey_fakerton") }

  it "sets resource name as :windows_feature" do
    expect(resource.resource_name).to eql(:windows_feature)
  end

  it "the feature_name property is the name_property" do
    expect(resource.feature_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :delete, :install, :remove actions" do
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "all property defaults to false" do
    expect(resource.all).to eql(false)
  end

  it "management_tools property defaults to false" do
    expect(resource.management_tools).to eql(false)
  end

  it "timeout property defaults to 600" do
    expect(resource.timeout).to eql(600)
  end

  it "install_method property defaults to :windows_feature_dism" do
    expect(resource.install_method).to eql(:windows_feature_dism)
  end

  it "install_method accepts :windows_feature_dism, :windows_feature_powershell, and :windows_feature_servermanagercmd" do
    expect { resource.install_method :windows_feature_dism }.not_to raise_error
    expect { resource.install_method :windows_feature_powershell }.not_to raise_error
    expect { resource.install_method :windows_feature_servermanagercmd }.not_to raise_error
    expect { resource.install_method "windows_feature_servermanagercmd" }.to raise_error(ArgumentError)
  end

end
