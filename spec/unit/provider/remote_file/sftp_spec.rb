#
# Author:: John Kerry (<john@kerryhouse.net>)
# Copyright:: Copyright 2013-2016, John Kerry
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

describe Chef::Provider::RemoteFile::SFTP do
  #built out dependencies
  let(:uri) { URI.Parse("sftp://opscode.com/seattle.txt") }

  describe "on initialization" do

    it "throws an argument exception when no path is given" do
      uri.path = ""
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

  end
end
