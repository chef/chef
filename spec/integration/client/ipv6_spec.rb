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

require "spec_helper"
require "support/shared/integration/integration_helper"
require "chef/mixin/shell_out"

describe "chef-client" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_zero_opts) { { host: "::1" } }

  let(:validation_pem) do
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

  let(:basic_config_file) do
    <<~END_CLIENT_RB
      chef_server_url "http://[::1]:8900"
      validation_key '#{path_to("config/validator.pem")}'
      cache_path '#{cache_path}'
      client_key '#{cache_path}/client.pem'
    END_CLIENT_RB
  end

  let(:client_rb_content) do
    basic_config_file
  end

  let(:chef_dir) { File.join(__dir__, "..", "..", "..") }

  let(:chef_client_cmd) { %Q{bundle exec chef-client --minimal-ohai -c "#{path_to("config/client.rb")}" -lwarn} }

  after do
    FileUtils.rm_rf(cache_path)
  end

  # Some Solaris test platforms are too old for IPv6. These tests should not
  # otherwise be platform dependent, so exclude solaris
  when_the_chef_server "is running on IPv6", :not_supported_on_solaris, :not_supported_on_gce, :not_supported_on_aix do

    when_the_repository "has a cookbook with a no-op recipe" do
      before do
        cookbook "noop", "1.0.0", {}, "recipes" => { "default.rb" => "#raise 'foo'" }
        file "config/client.rb", client_rb_content
        file "config/validator.pem", validation_pem
      end

      it "should complete with success" do
        result = shell_out("#{chef_client_cmd} -o 'noop::default'", cwd: chef_dir)
        result.error!
      end

    end

    when_the_repository "has a cookbook that hits server APIs" do

      before do
        recipe = <<-END_RECIPE
          actual_item = data_bag_item("expect_bag", "expect_item")
          if actual_item.key?("expect_key") and actual_item["expect_key"] == "expect_value"
            Chef::Log.info "lookin good"
          else
            Chef::Log.error("!" * 80)
            raise "unexpected data bag item content \#{actual_item.inspect}"
            Chef::Log.error("!" * 80)
          end

        END_RECIPE

        data_bag("expect_bag", { "expect_item" => { "expect_key" => "expect_value" } })

        cookbook "api-smoke-test", "1.0.0", {}, "recipes" => { "default.rb" => recipe }
      end

      before do
        file "config/client.rb", client_rb_content
        file "config/validator.pem", validation_pem
      end

      it "should complete with success" do
        result = shell_out("#{chef_client_cmd} -o 'api-smoke-test::default'", cwd: chef_dir)
        result.error!
      end

    end
  end
end
