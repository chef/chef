#
# Author:: Daniel DeLeo (<dan@chef.io>)
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
require "chef/mixin/shell_out"

describe "Knife cookbook API integration with IPv6", :workstation, :not_supported_on_gce do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_chef_server "is bound to IPv6" do
    let(:chef_zero_opts) { { host: "::1" } }

    let(:client_key) do
      <<~END_VALIDATION_PEM
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
      END_VALIDATION_PEM
    end

    let(:cache_path) do
      Dir.mktmpdir
    end

    let(:chef_dir) { File.join(__dir__, "..", "..", "..", "knife", "bin") }
    let(:knife) { "ruby '#{chef_dir}/knife'" }

    let(:knife_config_flag) { "-c '#{path_to("config/knife.rb")}'" }

    # Some Solaris test platforms are too old for IPv6. These tests should not
    # otherwise be platform dependent, so exclude solaris
    context "and the chef_server_url contains an IPv6 literal", :not_supported_on_solaris do

      # This provides helper functions we need such as #path_to()
      when_the_repository "has the cookbook to be uploaded" do

        let(:knife_rb_content) do
          <<~END_CLIENT_RB
            chef_server_url "http://[::1]:8900"
            syntax_check_cache_path '#{cache_path}'
            client_key '#{path_to("config/knifeuser.pem")}'
            node_name 'whoisthisis'
            cookbook_path '#{CHEF_SPEC_DATA}/cookbooks'
          END_CLIENT_RB
        end

        before do
          file "config/knife.rb", knife_rb_content
          file "config/knifeuser.pem", client_key
        end

        it "successfully uploads a cookbook" do
          shell_out!("#{knife} cookbook upload apache2 #{knife_config_flag}", cwd: chef_dir)
          versions_list_json = Chef::HTTP::Simple.new("http://[::1]:8900").get("/cookbooks/apache2", "accept" => "application/json")
          versions_list = Chef::JSONCompat.from_json(versions_list_json)
          expect(versions_list["apache2"]["versions"]).not_to be_empty
        end

        context "and the cookbook has been uploaded to the server" do
          before do
            shell_out!("#{knife} cookbook upload apache2 #{knife_config_flag}", cwd: chef_dir)
          end

          it "downloads the cookbook" do
            shell_out!("#{knife} cookbook download apache2 #{knife_config_flag} -d #{cache_path}", cwd: chef_dir)
            expect(Dir["#{cache_path}/*"].map { |entry| File.basename(entry) }).to include("apache2-0.0.1")
          end
        end

      end
    end
  end
end
