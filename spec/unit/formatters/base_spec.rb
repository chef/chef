#
# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Formatters::Base do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:formatter) { Chef::Formatters::Base.new(out, err) }
  let(:exception) do
    # An exception with a real backtrace.
    begin
      raise EOFError
    rescue EOFError => exc
    end
    exc
  end

  it "starts with an indentation of zero" do
    expect(formatter.output.indent).to eql(0)
  end

  it "increments it to two correctly" do
    formatter.indent_by(2)
    expect(formatter.output.indent).to eql(2)
  end

  it "increments it and then decrements it correctly" do
    formatter.indent_by(2)
    formatter.indent_by(-2)
    expect(formatter.output.indent).to eql(0)
  end

  it "does not allow negative indentation" do
    formatter.indent_by(-2)
    expect(formatter.output.indent).to eql(0)
  end

  it "humanizes EOFError exceptions for #registration_failed" do
    formatter.registration_failed("foo.example.com", exception, double("Chef::Config"))
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #node_load_failed" do
    formatter.node_load_failed("foo.example.com", exception, double("Chef::Config"))
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #run_list_expand_failed" do
    formatter.run_list_expand_failed(double("Chef::Node"), exception)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #cookbook_resolution_failed" do
    formatter.run_list_expand_failed(double("Expanded Run List"), exception)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #cookbook_sync_failed" do
    formatter.cookbook_sync_failed("foo.example.com", exception)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "outputs error information for failed resources with ignore_failure true" do
    resource = Chef::Resource::RubyBlock.new("test")
    resource.ignore_failure(true)
    formatter.resource_failed(resource, :run, exception)
    expect(out.string).to match(/Error executing action `run` on resource 'ruby_block\[test\]'/)
  end

  it "does not output error information for failed resources with ignore_failure :quiet" do
    resource = Chef::Resource::RubyBlock.new("test")
    resource.ignore_failure(:quiet)
    formatter.resource_failed(resource, :run, exception)
    expect(out.string).to eq("")
  end

  it "does not output error information for failed resources with ignore_failure 'quiet'" do
    resource = Chef::Resource::RubyBlock.new("test")
    resource.ignore_failure("quiet")
    formatter.resource_failed(resource, :run, exception)
    expect(out.string).to eq("")
  end
end
