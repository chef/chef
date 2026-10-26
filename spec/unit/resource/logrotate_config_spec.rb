#
# Copyright:: 2026, Tim Smith
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

describe Chef::Resource::LogrotateConfig do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::LogrotateConfig.new("nginx", run_context) }

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  describe "the path property" do
    it "is the name_property and is coerced to an Array" do
      expect(resource.path).to eql(["nginx"])
    end

    it "accepts a single String and coerces it to an Array" do
      resource.path("/var/log/nginx/*.log")
      expect(resource.path).to eql(["/var/log/nginx/*.log"])
    end

    it "accepts an Array of paths unchanged" do
      resource.path(%w{/var/log/a.log /var/log/b.log})
      expect(resource.path).to eql(%w{/var/log/a.log /var/log/b.log})
    end
  end

  describe "the filename property" do
    it "defaults to the resource name when the name is a bare app name" do
      expect(resource.filename).to eql("nginx")
    end

    it "sanitizes a glob path used as the resource name" do
      r = Chef::Resource::LogrotateConfig.new("/var/log/nginx/*.log", run_context)
      expect(r.filename).to eql("var-log-nginx-.log")
    end

    it "can be set explicitly" do
      resource.filename("00-nginx")
      expect(resource.filename).to eql("00-nginx")
    end
  end

  describe "property validation" do
    it "accepts a valid frequency" do
      expect { resource.frequency("daily") }.not_to raise_error
    end

    it "rejects an invalid frequency" do
      expect { resource.frequency("fortnightly") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "requires rotate to be an Integer" do
      expect { resource.rotate("abc") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "defaults directives to an empty Array" do
      expect(resource.directives).to eql([])
    end

    it "defaults mode to 0644" do
      expect(resource.mode).to eql("0644")
    end
  end

  describe "#config_content" do
    before { resource.path("/var/log/nginx/*.log") }

    it "wraps the log paths in a logrotate stanza" do
      expect(resource.config_content).to include("/var/log/nginx/*.log {\n")
      expect(resource.config_content).to end_with("}\n")
    end

    it "joins multiple paths with a space on the stanza header" do
      resource.path(%w{/var/log/a.log /var/log/b.log})
      expect(resource.config_content).to include("/var/log/a.log /var/log/b.log {\n")
    end

    it "renders valued directives as 'key value'" do
      resource.frequency("daily")
      resource.rotate(14)
      expect(resource.config_content).to include("  daily\n")
      expect(resource.config_content).to include("  rotate 14\n")
    end

    it "renders true booleans as bare directives" do
      resource.compress(true)
      expect(resource.config_content).to include("  compress\n")
    end

    it "omits false booleans entirely" do
      resource.compress(false)
      expect(resource.config_content).not_to include("compress")
    end

    it "renders copytruncate as a bare directive when true" do
      resource.copytruncate(true)
      expect(resource.config_content).to include("  copytruncate\n")
    end

    it "renders create with its mode and ownership argument" do
      resource.create("0640 nginx adm")
      expect(resource.config_content).to include("  create 0640 nginx adm\n")
    end

    it "wraps postrotate in a script block terminated by endscript" do
      resource.postrotate("/usr/bin/systemctl reload nginx")
      expect(resource.config_content).to include("  postrotate\n    /usr/bin/systemctl reload nginx\n  endscript\n")
    end

    it "renders each line of a multi-line script block" do
      resource.prerotate(["/bin/echo one", "/bin/echo two"])
      expect(resource.config_content).to include("  prerotate\n    /bin/echo one\n    /bin/echo two\n  endscript\n")
    end

    it "appends escape-hatch directives after the typed ones" do
      resource.frequency("daily")
      resource.directives(["su root adm", "dateext"])
      expect(resource.config_content).to include("  daily\n  su root adm\n  dateext\n")
    end

    it "emits a generated-by header comment as the first line" do
      expect(resource.config_content.lines.first).to match(/^# Generated by /)
    end
  end
end
