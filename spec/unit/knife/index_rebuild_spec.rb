#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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

describe Chef::Knife::IndexRebuild do

  let(:knife){Chef::Knife::IndexRebuild.new}
  let(:rest_client){mock(Chef::REST)}

  let(:stub_rest!) do
    knife.should_receive(:rest).and_return(rest_client)
  end

  before :each do
    # This keeps the test output clean
    knife.ui.stub!(:stdout).and_return(StringIO.new)
  end

  context "#grab_api_info" do
    let(:http_not_found_response) do
      e = Net::HTTPNotFound.new("1.1", 404, "blah")
      e.stub(:[]).with("x-ops-api-info").and_return(api_header_value)
      e
    end

    let(:http_server_exception) do
      Net::HTTPServerException.new("404: Not Found", http_not_found_response)
    end

    before(:each) do
      stub_rest!
      rest_client.stub(:get_rest).and_raise(http_server_exception)
    end

    context "against a Chef 11 server" do
      let(:api_header_value){"flavor=osc;version=11.0.0;erchef=1.2.3"}
      it "retrieves API information" do
        knife.grab_api_info.should == {"flavor" => "osc", "version" => "11.0.0", "erchef" => "1.2.3"}
      end
    end # Chef 11

    context "against a Chef 10 server" do
      let(:api_header_value){nil}
      it "finds no API information" do
        knife.grab_api_info.should == {}
      end
    end # Chef 10
  end # grab_api_info

  context "#unsupported_version?" do
    context "with Chef 11 API metadata" do
      it "is unsupported" do
        knife.unsupported_version?({"version" => "11.0.0", "flavor" => "osc", "erchef" => "1.2.3"}).should be_true
      end

      it "only truly relies on the version being non-nil" do
        knife.unsupported_version?({"version" => "1", "flavor" => "osc", "erchef" => "1.2.3"}).should be_true
      end
    end

    context "with Chef 10 API metadata" do
      it "is supported" do
        # Chef 10 will have no metadata
        knife.unsupported_version?({}).should be_false
      end
    end
  end # unsupported_version?

  context "Simulating a 'knife index rebuild' run" do

    before :each do
      knife.should_receive(:grab_api_info).and_return(api_info)
      server_specific_stubs!
    end

    context "against a Chef 11 server" do
      let(:api_info) do
        {"flavor" => "osc", 
          "version" => "11.0.0",
          "erchef" => "1.2.3"
        }
      end
      let(:server_specific_stubs!) do
        knife.should_receive(:unsupported_server_message).with(api_info)
        knife.should_receive(:exit).with(1)
      end

      it "should not be allowed" do
        knife.run
      end
    end

    context "against a Chef 10 server" do
      let(:api_info){ {} }
      let(:server_specific_stubs!) do
        stub_rest!
        rest_client.should_receive(:post_rest).with("/search/reindex", {}).and_return("representative output")
        knife.should_not_receive(:unsupported_server_message)
        knife.should_receive(:deprecated_server_message)
        knife.should_receive(:nag)
        knife.should_receive(:output).with("representative output")
      end
      it "should be allowed" do
        knife.run
      end
    end
  end

end



