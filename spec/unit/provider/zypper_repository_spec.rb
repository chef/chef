#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2017, Chef Software, Inc.
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

# Output of the command:
# => rpm -qa gpg-pubkey*
RPM_KEYS = <<-EOF
gpg-pubkey-307e3d54-4be01a65
gpg-pubkey-3dbdc284-53674dd4
EOF

# Output of the command:
# => gpg --with-fingerprint [FILE]
GPG_FINGER = <<-EOF
pub  2048R/7BD9BF62 2011-08-19 [expires: 2024-06-14]
      Key fingerprint = 573B FD6B 3D8F BC64 1079  A6AB ABF5 BD82 7BD9 BF62
uid                            nginx signing key <signing-key@nginx.com>
EOF

describe Chef::Provider::ZypperRepository do
  let(:new_resource) { Chef::Resource::ZypperRepository.new("nginx") }

  let(:shellout_env) { { env: { "LANG" => "en_US", "LANGUAGE" => "en_US" } } }
  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::ZypperRepository.new(new_resource, run_context)
  end

  let(:rpm_key_finger) do
    r = double("Mixlib::ShellOut", stdout: RPM_KEYS, exitstatus: 0, live_stream: true)
    allow(r).to receive(:run_command)
    r
  end

  let(:gpg_finger) do
    r = double("Mixlib::ShellOut", stdout: GPG_FINGER, exitstatus: 0, live_stream: true)
    allow(r).to receive(:run_command)
    r
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end
end
