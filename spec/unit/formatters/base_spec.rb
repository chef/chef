#
# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

  it "starts with an indentation of zero" do
    expect(formatter.output.indent).to eql(0)
  end

  it "increments it to two correctly" do
    formatter.indent_by(2)
    expect(formatter.output.indent).to eql(2)
  end

  it "increments it and then decrements it corectly" do
    formatter.indent_by(2)
    formatter.indent_by(-2)
    expect(formatter.output.indent).to eql(0)
  end

  it "does not allow negative indentation" do
    formatter.indent_by(-2)
    expect(formatter.output.indent).to eql(0)
  end

  it "humanizes EOFError exceptions for #registration_failed" do
    formatter.registration_failed("foo.example.com", EOFError.new, double("Chef::Config"))
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #node_load_failed" do
    formatter.node_load_failed("foo.example.com", EOFError.new, double("Chef::Config"))
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #run_list_expand_failed" do
    formatter.run_list_expand_failed(double("Chef::Node"), EOFError.new)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #cookbook_resolution_failed" do
    formatter.run_list_expand_failed(double("Expanded Run List"), EOFError.new)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end

  it "humanizes EOFError exceptions for #cookbook_sync_failed" do
    formatter.cookbook_sync_failed("foo.example.com", EOFError.new)
    expect(out.string).to match(/Received an EOF on transport socket/)
  end
end
