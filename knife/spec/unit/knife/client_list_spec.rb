#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2011-2016, Thomas Bishop
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

require "knife_spec_helper"

describe Chef::Knife::ClientList do
  before(:each) do
    @knife = Chef::Knife::ClientList.new
    @knife.name_args = [ "adam" ]
  end

  describe "run" do
    it "should list the clients" do
      expect(Chef::ApiClientV1).to receive(:list)
      expect(@knife).to receive(:format_list_for_display)
      @knife.run
    end
  end
end
