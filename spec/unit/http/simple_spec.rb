#
# Author:: Serdar Sutay (<serdar@chef.io>)
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

describe Chef::HTTP::Simple do
  it "should have content length validation middleware after compressor middleware" do
    client = Chef::HTTP::Simple.new("dummy.com")
    middlewares = client.instance_variable_get(:@middlewares)
    content_length = middlewares.find_index { |e| e.is_a? Chef::HTTP::ValidateContentLength }
    decompressor = middlewares.find_index { |e| e.is_a? Chef::HTTP::Decompressor }

    expect(content_length).not_to be_nil
    expect(decompressor).not_to be_nil
    expect(decompressor < content_length).to be_truthy
  end
end
