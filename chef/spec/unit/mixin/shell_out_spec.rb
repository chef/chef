#
# Author:: Michael Hale (<mikehale@gmail.com>)
# Copyright:: Copyright (c) 2011 Michael Hale
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Mixin::ShellOut do
  include Chef::Mixin::ShellOut

  describe "set_environment" do
    it "should respect base_shell_environment when defined" do
      Chef::Config[:override_shell_environment] = {"CHEF" => "1"}
      shell_out("env").stdout.strip.should == "CHEF=1\nLC_ALL=C"
    end
  end

end
