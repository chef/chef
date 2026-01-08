#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Author:: Tim Smith (tsmith@chef.io)
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

describe Chef::Resource::WindowsUpdateSettings do
  let(:resource) { Chef::Resource::WindowsUpdateSettings.new("foobar") }

  it "sets resource name as :windows_update_settings" do
    expect(resource.resource_name).to eql(:windows_update_settings)
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports :set and legacy :enable actions" do
    expect { resource.action :set }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
  end

  it "raises an error if scheduled_install_day isn't a validate day" do
    expect { resource.scheduled_install_day "Saturday" }.not_to raise_error
    expect { resource.scheduled_install_day "Sunday" }.not_to raise_error
    expect { resource.scheduled_install_day "Extraday" }.to raise_error(ArgumentError)
  end

  it "raises an error if automatic_update_option isn't a validate option" do
    expect { resource.automatic_update_option 2 }.not_to raise_error
    expect { resource.automatic_update_option :notify }.not_to raise_error
    expect { resource.automatic_update_option :nope }.to raise_error(ArgumentError)
  end

  it "coerces legacy Integer value in automatic_update_option to friendly symbol" do
    resource.automatic_update_option 2
    expect(resource.automatic_update_option).to eql(:notify)
  end

  it "raises an error if scheduled_install_hour isn't a 24 hour clock hour" do
    expect { resource.scheduled_install_hour 2 }.not_to raise_error
    expect { resource.scheduled_install_hour 0 }.to raise_error(ArgumentError)
    expect { resource.scheduled_install_hour 25 }.to raise_error(ArgumentError)
  end

  it "raises an error if custom_detection_frequency isn't a valid frequency" do
    expect { resource.custom_detection_frequency 0 }.not_to raise_error
    expect { resource.custom_detection_frequency 23 }.to raise_error(ArgumentError)
  end
end
