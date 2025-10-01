#
# Author:: Steven Danna (<steve@chef.io>)
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

require "knife_spec_helper"

describe Chef::Knife::Raw do
  let(:rest) do
    r = double("Chef::Knife::Raw::RawInputServerAPI")
    allow(Chef::Knife::Raw::RawInputServerAPI).to receive(:new).and_return(r)
    r
  end

  let(:knife) do
    k = Chef::Knife::Raw.new
    k.config[:method] = "GET"
    k.name_args = [ "/nodes" ]
    k
  end

  describe "run" do
    it "should set the x-ops-request-source header when --proxy-auth is set" do
      knife.config[:proxy_auth] = true
      expect(rest).to receive(:request).with(:GET, "/nodes",
        { "Content-Type" => "application/json",
          "x-ops-request-source" => "web" }, false)
      knife.run
    end
  end
end
