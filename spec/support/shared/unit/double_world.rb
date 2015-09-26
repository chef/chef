#
# Author:: John Keiser <jkeiser@chef.io>
# Copyright:: Copyright (c) 2015 John Keiser.
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
# Mocks File and ShellOut.
#
# world.files["/etc/rc.d/init.d"] = "blah" means that /etc/rc.d/init.d is a file with contents "blah."
# world.commands["shellme"] = "result" means that when shell_out! calls "shellme", it will return "result" in stdout.
# world.commands["shellme"] = 10 means that when shell_out! calls "shellme", it will return exit code 10
# world.commands["shellme"] = { code: 10, stdout: "result", stderr: "result2"}
#
shared_context "double world" do
  let(:world) { DoubleWorld.new }
  before do
    allow(::File).to receive(:exists?) { |f| world.files.has_key?(f) }
    allow(::File).to receive(:executable?) { |f| world.files.has_key?(f) }
    allow(::File).to receive(:open) { |f| StringIO.new(world.files[f]) }

    allow(::Chef::Mixin::ShellOut).to receive(:shell_out!) do |c|
      raise "hi"
      result = world.commands[c]
      case result
      when String
        Mash.new(stdout: result)
      when Integer
        Mash.new(exitstatus: result)
      when Hash
        Mash.new(result)
      else
        raise ArgumentError, result
      end
    end
  end

  private

  class DoubleWorld
    def initialize
      @files = {}
      @commands = {}
    end
    attr_reader :files
    attr_reader :commands
  end
end
