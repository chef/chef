#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::Mixin::ShellOut do
  include Chef::Mixin::ShellOut

  describe "shell_out_with_systems_locale" do
    describe "when environment['LC_ALL'] is not set" do
      it "should use the default shell_out setting" do
        cmd = if windows?
                shell_out_with_systems_locale("echo %LC_ALL%")
              else
                shell_out_with_systems_locale("echo $LC_ALL")
              end

        expect(cmd.stdout.chomp).to match_environment_variable("LC_ALL")
      end
    end

    describe "when environment['LC_ALL'] is set" do
      it "should use the option's setting" do
        cmd = if windows?
                shell_out_with_systems_locale("echo %LC_ALL%", :environment => { "LC_ALL" => "POSIX" })
              else
                shell_out_with_systems_locale("echo $LC_ALL", :environment => { "LC_ALL" => "POSIX" })
              end

        expect(cmd.stdout.chomp).to eq "POSIX"
      end
    end
  end
end
