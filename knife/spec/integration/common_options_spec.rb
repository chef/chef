#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "chef/knife/raw"

describe "knife common options", :workstation do
  include IntegrationSupport
  include KnifeSupport

  before do
    # Allow this for testing the various port binding stuffs. Remove when
    # we kill off --listen.
    Chef::Config.treat_deprecation_warnings_as_errors(false)
  end

  let(:local_listen_warning) { /\Awarn:.*local.*listen.*$/im }

  when_the_repository "has a node" do
    before { file "nodes/x.json", {} }

    context "When chef_zero.enabled is true" do
      before(:each) do
        Chef::Config.chef_zero.enabled = true
      end

      it "knife raw /nodes/x should retrieve the node in socketless mode" do
        Chef::Config.treat_deprecation_warnings_as_errors(true)
        knife("raw /nodes/x").should_succeed( /"name": "x"/ )
      end

      it "knife raw /nodes/x should retrieve the node" do
        knife("raw --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
      end

      context "And chef_zero.port is 9999" do
        before(:each) { Chef::Config.chef_zero.port = 9999 }

        it "knife raw /nodes/x should retrieve the node" do
          knife("raw --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
          expect(Chef::Config.chef_server_url).to eq("chefzero://localhost:9999")
        end
      end

      # 0.0.0.0 is not a valid address to bind to on windows.
      context "And chef_zero.host is 0.0.0.0", :unix_only do
        before(:each) { Chef::Config.chef_zero.host = "0.0.0.0" }

        it "knife raw /nodes/x should retrieve the role" do
          knife("raw --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
        end
      end

      context "and there is a private key" do
        before do
          file "mykey.pem", <<~EOM
            -----BEGIN RSA PRIVATE KEY-----
            MIIEogIBAAKCAQEApubutqtYYQ5UiA9QhWP7UvSmsfHsAoPKEVVPdVW/e8Svwpyf
            0Xef6OFWVmBE+W442ZjLOe2y6p2nSnaq4y7dg99NFz6X+16mcKiCbj0RCiGqCvCk
            NftHhTgO9/RFvCbmKZ1RKNob1YzLrFpxBHaSh9po+DGWhApcd+I+op+ZzvDgXhNn
            0nauZu3rZmApI/r7EEAOjFedAXs7VPNXhhtZAiLSAVIrwU3ZajtSzgXOxbNzgj5O
            AAAMmThK+71qPdffAdO4J198H6/MY04qgtFo7vumzCq0UCaGZfmeI1UNE4+xQWwP
            HJ3pDAP61C6Ebx2snI2kAd9QMx9Y78nIedRHPwIDAQABAoIBAHssRtPM1GacWsom
            8zfeN6ZbI4KDlbetZz0vhnqDk9NVrpijWlcOP5dwZXVNitnB/HaqCqFvyPDY9JNB
            zI/pEFW4QH59FVDP42mVEt0keCTP/1wfiDDGh1vLqVBYl/ZphscDcNgDTzNkuxMx
            k+LFVxKnn3w7rGc59lALSkpeGvbbIDjp3LUMlUeCF8CIFyYZh9ZvXe4OCxYdyjxb
            i8tnMLKvJ4Psbh5jMapsu3rHQkfPdqzztQUz8vs0NYwP5vWge46FUyk+WNm/IhbJ
            G3YM22nwUS8Eu2bmTtADSJolATbCSkOwQ1D+Fybz/4obfYeGaCdOqB05ttubhenV
            ShsAb7ECgYEA20ecRVxw2S7qA7sqJ4NuYOg9TpfGooptYNA1IP971eB6SaGAelEL
            awYkGNuu2URmm5ElZpwJFFTDLGA7t2zB2xI1FeySPPIVPvJGSiZoFQOVlIg9WQzK
            7jTtFQ/tOMrF+bigEUJh5bP1/7HzqSpuOsPjEUb2aoCTp+tpiRGL7TUCgYEAwtns
            g3ysrSEcTzpSv7fQRJRk1lkBhatgNd0oc+ikzf74DaVLhBg1jvSThDhiDCdB59mr
            Jh41cnR1XqE8jmdQbCDRiFrI1Pq6TPaDZFcovDVE1gue9x86v3FOH2ukPG4d2/Xy
            HevXjThtpMMsWFi0JYXuzXuV5HOvLZiP8sN3lSMCgYANpdxdGM7RRbE9ADY0dWK2
            V14ReTLcxP7fyrWz0xLzEeCqmomzkz3BsIUoouu0DCTSw+rvAwExqcDoDylIVlWO
            fAifz7SeZHbcDxo+3TsXK7zwnLYsx7YNs2+aIv6hzUUbMNmNmXMcZ+IEwx+mRMTN
            lYmZdrA5mr0V83oDFPt/jQKBgC74RVE03pMlZiObFZNtheDiPKSG9Bz6wMh7NWMr
            c37MtZLkg52mEFMTlfPLe6ceV37CM8WOhqe+dwSGrYhOU06dYqUR7VOZ1Qr0aZvo
            fsNPu/Y0+u7rMkgv0fs1AXQnvz7kvKaF0YITVirfeXMafuKEtJoH7owRbur42cpV
            YCAtAoGAP1rHOc+w0RUcBK3sY7aErrih0OPh9U5bvJsrw1C0FIZhCEoDVA+fNIQL
            syHLXYFNy0OxMtH/bBAXBGNHd9gf5uOnqh0pYcbe/uRAxumC7Rl0cL509eURiA2T
            +vFmf54y9YdnLXaqv+FhJT6B6V7WX7IpU9BMqJY1cJYXHuHG2KA=
            -----END RSA PRIVATE KEY-----
          EOM
        end

        it "knife raw /nodes/x should retrieve the node" do
          knife("raw --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
        end
      end
    end

    it "knife raw -z /nodes/x retrieves the node in socketless mode" do
      Chef::Config.treat_deprecation_warnings_as_errors(true)
      knife("raw -z /nodes/x").should_succeed( /"name": "x"/ )
    end

    it "knife raw -z /nodes/x retrieves the node" do
      knife("raw -z --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
    end

    it "knife raw --local-mode /nodes/x retrieves the node" do
      knife("raw --local-mode --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
    end

    it "knife raw -z --chef-zero-port=9999 /nodes/x retrieves the node" do
      knife("raw -z --chef-zero-port=9999 --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
      expect(Chef::Config.chef_server_url).to eq("chefzero://localhost:9999")
    end

    context "when the default port (8889) is already bound" do
      before :each do

        @server = ChefZero::Server.new(host: "localhost", port: 8889)
        @server.start_background
      rescue Errno::EADDRINUSE
        # OK.  Don't care who has it in use, as long as *someone* does.

      end
      after :each do
        @server.stop if @server
      end

      it "knife raw -z /nodes/x retrieves the node" do
        knife("raw -z --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
        expect(URI(Chef::Config.chef_server_url).port).to be > 8889
      end
    end

    context "when port 9999 is already bound" do
      before :each do

        @server = ChefZero::Server.new(host: "localhost", port: 9999)
        @server.start_background
      rescue Errno::EADDRINUSE
        # OK.  Don't care who has it in use, as long as *someone* does.

      end
      after :each do
        @server.stop if @server
      end

      it "knife raw -z --chef-zero-port=9999-20000 /nodes/x" do
        knife("raw -z --chef-zero-port=9999-20000 --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
        expect(URI(Chef::Config.chef_server_url).port).to be > 9999
      end

      it "knife raw -z --chef-zero-port=9999-9999,19423" do
        knife("raw -z --chef-zero-port=9999-9999,19423 --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
        expect(URI(Chef::Config.chef_server_url).port).to be == 19423
      end
    end

    it "knife raw -z --chef-zero-port=9999 /nodes/x retrieves the node" do
      knife("raw -z --chef-zero-port=9999 --listen /nodes/x").should_succeed( /"name": "x"/, stderr: local_listen_warning )
      expect(Chef::Config.chef_server_url).to eq("chefzero://localhost:9999")
    end
  end
end
