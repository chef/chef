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

describe Chef::Resource::SelinuxFcontext do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxFcontext.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:manage) }
  let(:restoreconf) { double("shellout", stdout: "restorecon reset /var/www/html/index.html context unconfined_u:object_r:user_home_t:s0->unconfined_u:object_r:httpd_sys_content_t:s0") }

  it "sets file_spec proprty as name_property" do
    expect(resource.file_spec).to eql("fakey_fakerton")
  end

  it "sets the default action as :manage" do
    expect(resource.action).to eql([:manage])
  end

  it "supports :manage, :addormodify, :add, :modify, :delete actions" do
    expect { resource.action :manage }.not_to raise_error
    expect { resource.action :addormodify }.not_to raise_error
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :modify }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "checks 'a', 'f', 'd', 'c', 'b', 's', 'l', 'p' as valid file_type property values" do
    expect { resource.file_type "a" }.not_to raise_error
    expect { resource.file_type "f" }.not_to raise_error
    expect { resource.file_type "d" }.not_to raise_error
    expect { resource.file_type "c" }.not_to raise_error
    expect { resource.file_type "b" }.not_to raise_error
    expect { resource.file_type "s" }.not_to raise_error
    expect { resource.file_type "l" }.not_to raise_error
    expect { resource.file_type "p" }.not_to raise_error
  end

  it "sets default value for file_type property to 'a'" do
    expect(resource.file_type).to eql("a")
  end

  describe "#relabel_files" do
    it "returns verbose output with details of the file for which SELinux config is restored" do
      allow(provider).to receive(:shell_out!).and_return(restoreconf)
      expect(provider.relabel_files).to eql(restoreconf)
    end
  end
end
