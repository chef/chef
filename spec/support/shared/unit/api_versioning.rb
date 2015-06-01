#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

shared_examples_for "version handling" do
  before do
    allow(rest_v1).to receive(http_verb).and_raise(exception_406)
  end

  context "when the server does not support the min or max server API version that Chef::User supports" do
    before do
      allow(object).to receive(:handle_version_http_exception).and_return(false)
    end

    it "raises the original exception" do
      expect{ object.send(method) }.to raise_error(exception_406)
    end
  end # when the server does not support the min or max server API version that Chef::User supports
end # version handling
