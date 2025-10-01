#
# Author:: John Keiser <jkeiser@chef.io>
# Copyright:: Copyright 2015-2016, John Keiser.
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

#
# Mocks shellout results. Examples:
#   mock_shellout_command("systemctl --all", exitstatus: 1)
#
class MockShellout
  module RSpec
    def mock_shellout_command(command, **result)
      allow(::Mixlib::ShellOut).to receive(:new).with(command, anything).and_return MockShellout.new(**result)
    end
  end

  def initialize(**properties)
    @properties = {
      stdout: "",
      stderr: "",
      exitstatus: 0,
    }.merge(properties)
  end

  def method_missing(name, *args)
    @properties[name.to_sym]
  end

  def error?
    exitstatus != 0
  end

  def error!
    raise Mixlib::ShellOut::ShellCommandFailed, "Expected process to exit with 0, but received #{exitstatus}" if error?
  end
end
