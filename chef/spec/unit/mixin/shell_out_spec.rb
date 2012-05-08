#
# Author:: Ho-Sheng Hsiao (hosh@opscode.com)
# Code derived from spec/unit/mixin/command_spec.rb
#
# Original header:
# Author:: Hongli Lai (hongli@phusion.nl)
# Copyright:: Copyright (c) 2009 Phusion
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

require 'spec_helper'

describe Chef::Mixin::ShellOut do
  include Chef::Mixin::ShellOut

  describe '#run_command_compatible_options' do
    subject { run_command_compatible_options(command_args) }
    let(:command_args) { [ cmd, options ] }
    let(:cmd) { "echo '#{rand(1000)}'" }

    context 'without options' do
      let(:command_args) { [ cmd ] }

      it 'should not edit command args' do
        should eql(command_args)
      end
    end

    context 'without deprecated options' do
      let(:options) { { :environment => environment } }
      let(:environment) { { 'LC_ALL' => 'C' } }

      it 'should not edit command args' do
        should eql(command_args)
      end
    end

    context 'with :command_log_level option' do
      let(:options) { { :command_log_level => command_log_level } }
      let(:command_log_level) { :warn }

      it 'should convert :command_log_level to :log_level' do
        should eql [ cmd, { :log_level => command_log_level } ]
      end

      it 'should emit a deprecation warning'
    end

    context 'with :command_log_prepend option' do
      let(:options) { { :command_log_prepend => command_log_prepend } }
      let(:command_log_prepend) { 'PROVIDER:' }

      it 'should convert :command_log_prepend to :log_tag' do
        should eql [ cmd, { :log_tag => command_log_prepend } ]
      end

      it 'should emit a deprecation warning'
    end

    pending "with 'command_log_level' option"
    pending "with 'command_log_prepend' option"
  end
end
