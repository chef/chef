#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

describe Chef::Digester do
  before(:each) do
    @cache = Chef::Digester.instance
  end

  describe "when computing checksums of cookbook files and templates" do

    it "proxies the class method checksum_for_file to the instance" do
      @cache.should_receive(:checksum_for_file).with("a_file_or_a_fail")
      Chef::Digester.checksum_for_file("a_file_or_a_fail")
    end

    it "computes a checksum of a file" do
      fixture_file = CHEF_SPEC_DATA + "/checksum/random.txt"
      expected = "09ee9c8cc70501763563bcf9c218d71b2fbf4186bf8e1e0da07f0f42c80a3394"
      @cache.checksum_for_file(fixture_file).should == expected
    end

    it "generates a checksum from a non-file IO object" do
      io = StringIO.new("riseofthemachines\nriseofthechefs\n")
      expected_md5 = '0e157ac1e2dd73191b76067fb6b4bceb'
      @cache.generate_md5_checksum(io).should == expected_md5
    end

  end

end

