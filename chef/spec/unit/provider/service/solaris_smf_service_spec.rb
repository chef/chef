#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Provider::Service::Solaris do
  include SpecHelpers::Providers::Service
  let(:new_resource) { Chef::Resource::Service.new(service_name) }

  describe '#load_current_resource' do
    subject { given; provider.load_current_resource }

    let(:given) do
      assume_svcs
      assume_service_is_running
    end

    let(:assume_svcs) { provider.stub!(:svcs_exists?).and_return(true) }
    let(:assume_service_is_running) { provider.should_receive(:service_status?).and_return(true) }
    let(:assume_service_has_stopped) { provider.should_receive(:service_status?).and_return(false) }

    context 'without /bin/svcs' do
      subject { given; provider.load_current_resource }
      let(:given) { assume_no_svcs }
      let(:assume_no_svcs) { provider.stub!(:svcs_exists?).and_return(false) }

      it { lambda { subject }.should raise_error(Chef::Exceptions::Service) }
    end

    it "should create a current resource with the name of the new resource" do
      should_not be_nil
      provider.current_resource.service_name.should eql(new_resource.service_name)
    end

    it "should return the current resource" do
      subject # Need to load it before testing it
      should eql(provider.current_resource)
    end

    context 'when discovering the current service state' do
      context 'when service is running' do
        it 'should running as true' do
          should_not be_nil
          provider.current_resource.running.should be_true
        end

        it 'should set enabled as true' do
          should_not be_nil
          provider.current_resource.enabled.should be_true
        end
      end

      context 'when service has stopped' do
        let(:given) do
          assume_svcs
          assume_service_has_stopped
        end

        it 'should running as false' do
          should_not be_nil
          provider.current_resource.running.should be_false
        end

        it 'should set enabled as false' do
          should_not be_nil
          provider.current_resource.enabled.should be_false
        end
      end
    end
  end

  context 'when starting service' do
    let(:given) do
      assume_shell_out_to_svcadm
      assume_service_will_start

      provider.current_resource = current_resource
      assume_service_was_stopped
    end

    let(:assume_shell_out_to_svcadm) { provider.should_receive(:shell_out!).with("/usr/sbin/svcadm enable chef")  }
    let(:assume_service_will_start) { provider.should_receive(:service_status?).and_return(true) }
    let(:assume_service_was_stopped) { provider.current_resource.enabled false }

    describe "#enable_service" do
      subject { given; provider.enable_service }

      it "should call `svcadm enable ${service_name}`" do
        should be_true
      end
    end

    describe "#start_service" do
      subject { given; provider.start_service }

      it "should call `svcadm start ${service_name}`" do
        should be_true
      end
    end
  end

  context 'when stopping service' do
    let(:given) do
      assume_shell_out_to_svcadm
      assume_service_will_stop

      provider.current_resource = current_resource
      assume_service_was_started
    end

    let(:assume_shell_out_to_svcadm) { provider.should_receive(:shell_out!).with("/usr/sbin/svcadm disable chef")  }
    let(:assume_service_will_stop) { provider.should_receive(:service_status?).and_return(false) }
    let(:assume_service_was_started) { provider.current_resource.enabled true }

    describe "#disable_service" do
      subject { given; provider.disable_service }

      it "should call `svcadm disable ${service_name}`" do
        should be_true
      end
    end

    describe "#stop_service" do
      subject { given; provider.stop_service }

      it "should call `svcadm stop ${service_name}`" do
        should be_true
      end
    end
  end

  context '#reload_service' do
    subject { given; provider.reload_service }
    let(:given) { assume_shell_out_to_svcadm }
    let(:assume_shell_out_to_svcadm) { provider.should_receive(:shell_out!).with("/usr/sbin/svcadm refresh chef").and_return(0)  }

    it "should call `svcadm refresh ${service_name}`" do
      should be_true
    end
  end

  describe '#service_status?' do
    subject { given; provider.service_status? }

    let(:given) do
      should_shell_out_to_svcs
      provider.current_resource = current_resource
    end

    let(:should_shell_out_to_svcs) { provider.should_receive(:shell_out!).with(status_cmd).and_return(status) }
    let(:stdout) { status_output }
    let(:status_cmd) { "#{provider.status_command} #{service_name}" }

    context 'when /bin/svcs reports service online' do
      # TODO: get real-world output from /bin/svcs
      let(:status_output) { "state online" }
      it { should be_true }
    end

    context 'when /bin/svcs reports service offline' do
      # TODO: get real-world output from /bin/svcs
      let(:status_output) { "state offline" }
      it { should be_false }
      it { should_not be_nil }
    end
  end
end
