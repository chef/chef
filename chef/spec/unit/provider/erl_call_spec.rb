#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

describe Chef::Provider::ErlCall do
  include SpecHelpers::Provider

  let(:erl_call_name) { 'test' }
  let(:new_resource) { Chef::Resource::ErlCall.new(erl_call_name, node).tap(&with_attributes.call(new_resource_attributes)) }

  let(:new_resource_attributes) do
    { :code => code,
      :node_name => node_name,
      :name => erl_call_name }
  end

  let(:code) { "io:format(\"burritos\", [])." }
  let(:node_name) { "chef@localhost" }

  let(:stdout) { '{ok, woohoo}' }
  let(:stderr) { '' }

  it "should return a Chef::Provider::ErlCall object" do
    provider.should be_a_kind_of(Chef::Provider::ErlCall)
  end

  it "should return true" do
    provider.load_current_resource.should eql(true)
  end

  describe "when running a distributed erl call resource" do
    before do
      new_resource.cookie      "nomnomnom"
      new_resource.distributed true
      new_resource.name_type   "sname"
    end

    let(:expected_cmd) { "erl_call -e -s -sname chef@localhost -c nomnomnom" }

    it "should write to stdin of the erl_call command" do
      provider.should_receive(:shell_out!).with(expected_cmd, :input => code).and_return(status)
      provider.action_run
    end
  end

  describe "when running a local erl call resource" do
    before do
      new_resource.cookie      nil
      new_resource.distributed false
      new_resource.name_type   "name"
    end

    it "should write to stdin of the erl_call command" do
      provider.
        should_receive(:shell_out!).
        with("erl_call -e  -name chef@localhost ", :input => code).
        and_return(status)

      provider.action_run
    end
  end

  describe '#erl_call_cmd' do
    subject { given; provider.erl_call_cmd }
    let(:given) { assume_new_resource }

    let(:new_resource_attributes) do
      { :code        => code,
        :node_name   => node_name,
        :name        => erl_call_name,
        :name_type   => name_type,
        :distributed => distributed?,
        :cookie      => cookie }
    end

    let(:name_type)    { 'name' }
    let(:cookie)       { nil }
    let(:distributed?) { false }

    context 'when name type is name' do
      let(:name_type) { 'name' }

      it 'should return with the -name flag' do
        should match /^erl_call -e.*\s+-name\s+/
      end

      it 'should pass the name' do
        should match /^erl_call -e.*\s+-name\s+#{Regexp.escape(node_name)}/
      end
    end

    context 'when name type is sname' do
      let(:name_type) { 'sname' }

      it 'should return with the -sname flag' do
        should match /^erl_call -e.*\s+-sname\s+/
      end

      it 'should pass the sname' do
        should match /^erl_call -e.*\s+-sname\s+#{Regexp.escape(node_name)}/
      end
    end

    context 'when distributed' do
      let(:distributed?) { true }

      it 'should return with the -s flag' do
        should match /^erl_call -e.*\s+-s\s+/
      end
    end

    context 'when not distributed' do
      let(:distributed?) { false }

      it 'should return with the -s flag' do
        should_not match /^erl_call -e.*\s+-s\s+/
      end
    end

    context 'with cookie' do
      let(:cookie) { rand(100000000).to_s }

      it 'should return with the -c flag' do
        should match /^erl_call -e.*\s+-c\s+/
      end

      it 'should pass the cookie' do
        should match /^erl_call -e.*\s+-c\s+#{Regexp.escape(cookie)}/
      end
    end

    context 'without cookie' do
      let(:cookie) { nil }

      it 'should not return with the -c flag' do
        should_not match /^erl_call -e.*\s+-c\s+/
      end
    end
  end

end
