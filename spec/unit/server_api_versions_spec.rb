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

describe Chef::ServerAPIVersions do
  before do
    Chef::ServerAPIVersions.instance.reset!
  end

  describe "#reset!" do
    it "resets the version information" do
      Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 0, "max_version" => 2 })
      Chef::ServerAPIVersions.instance.reset!
      expect(Chef::ServerAPIVersions.instance.min_server_version).to be_nil
    end

    it "resets the unversioned flag" do
      Chef::ServerAPIVersions.instance.unversioned!
      Chef::ServerAPIVersions.instance.reset!
      expect(Chef::ServerAPIVersions.instance.unversioned?).to be false
    end
  end

  describe "#min_server_version" do
    it "returns nil if no versions have been recorded" do
      expect(Chef::ServerAPIVersions.instance.min_server_version).to be_nil
    end
    it "returns 0 if unversioned" do
      Chef::ServerAPIVersions.instance.unversioned!
      expect(Chef::ServerAPIVersions.instance.min_server_version).to eq(0)
    end
    it "returns the correct value" do
      Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 0, "max_version" => 2 })
      expect(Chef::ServerAPIVersions.instance.min_server_version).to eq(0)
    end
  end

  describe "#max_server_version" do
    it "returns nil if no versions have been recorded" do
      expect(Chef::ServerAPIVersions.instance.max_server_version).to be_nil
    end
    it "returns 0 if unversioned" do
      Chef::ServerAPIVersions.instance.unversioned!
      expect(Chef::ServerAPIVersions.instance.min_server_version).to eq(0)
    end
    it "returns the correct value" do
      Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 0, "max_version" => 2 })
      expect(Chef::ServerAPIVersions.instance.max_server_version).to eq(2)
    end
  end
end
