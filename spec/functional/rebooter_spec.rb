#
# Author:: Chris Doherty <cdoherty@chef.io>)
# Copyright:: Copyright 2014-2016, Chef, Inc.
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

describe Chef::Platform::Rebooter do

  let(:reboot_info) do
    {
      :delay_mins => 5,
      :requested_by => "reboot resource functional test",
      :reason => "rebooter spec test",
    }
  end

  def create_resource
    resource = Chef::Resource::Reboot.new(expected[:requested_by], run_context)
    resource.delay_mins(expected[:delay_mins])
    resource.reason(expected[:reason])
    resource
  end

  let(:run_context) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  let(:expected) do
    {
      :windows => "#{ENV['SYSTEMROOT']}/System32/shutdown.exe /r /t 300 /c \"rebooter spec test\"",
      :linux => 'shutdown -r +5 "rebooter spec test"',
    }
  end

  let(:rebooter) { Chef::Platform::Rebooter }

  describe "#reboot_if_needed!" do

    it "should not call #shell_out! when reboot has not been requested" do
      expect(rebooter).to receive(:shell_out!).exactly(0).times
      expect(rebooter).to receive(:reboot_if_needed!).once.and_call_original
      rebooter.reboot_if_needed!(run_context.node)
    end

    describe "calling #shell_out! to reboot" do

      before(:each) do
        run_context.request_reboot(reboot_info)
      end

      after(:each) do
        run_context.cancel_reboot
      end

      shared_context "test a reboot method" do
        def test_rebooter_method(method_sym, is_windows, expected_reboot_str)
          allow(ChefConfig).to receive(:windows?).and_return(is_windows)
          expect(rebooter).to receive(:shell_out!).once.with(expected_reboot_str)
          expect(rebooter).to receive(:raise).with(Chef::Exceptions::Reboot)
          expect(rebooter).to receive(method_sym).once.and_call_original
          rebooter.send(method_sym, run_context.node)
        end
      end

      describe "when using #reboot_if_needed!" do
        include_context "test a reboot method"

        it "should produce the correct string on Windows", :windows_only do
          test_rebooter_method(:reboot_if_needed!, true, expected[:windows])
        end

        it "should produce the correct (Linux-specific) string on non-Windows" do
          test_rebooter_method(:reboot_if_needed!, false, expected[:linux])
        end
      end

      describe "when using #reboot!" do
        include_context "test a reboot method"

        it "should produce the correct string on Windows", :windows_only do
          test_rebooter_method(:reboot!, true, expected[:windows])
        end

        it "should produce the correct (Linux-specific) string on non-Windows" do
          test_rebooter_method(:reboot!, false, expected[:linux])
        end
      end
    end
  end
end
