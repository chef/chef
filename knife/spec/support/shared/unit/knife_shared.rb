#
# Author:: Tyler Cloke (<tyler@chef.io>)
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

shared_examples_for "mandatory field missing" do
  context "when field is nil" do
    before do
      knife.name_args = name_args
    end

    it "exits 1" do
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "prints the usage" do
      expect(knife).to receive(:show_usage)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "prints a relevant error message" do
      expect { knife.run }.to raise_error(SystemExit)
      expect(stderr.string).to match(/You must specify a #{fieldname}/)
    end
  end
end
