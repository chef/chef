require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-client" do
  extend IntegrationSupport
  include Chef::Mixin::ShellOut

  when_the_repository "has a cookbook with a no-op recipe" do
    file 'cookbooks/x/recipes/default.rb', ''

    it "should complete with success" do
      file 'config/client.rb', <<EOM
chef_zero.enabled true
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
      result.error!
    end

    context 'and a private key' do
      file 'mykey.pem', <<EOM
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

      it "should complete with success even with a client key" do
        file 'config/client.rb', <<EOM
chef_zero.enabled true
client_key "#{path_to('mykey.pem')}"
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

        chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
        result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
        result.error!
      end
    end

    it "should complete with success when passed the -z flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed the --zero flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' --zero", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed -z and --chef-zero-port" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
checksum_path "#{path_to('config/checksums')}"
file_cache_path "#{path_to('config/cache')}"
file_backup_path "#{path_to('config/backup')}"
EOM

      chef_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "bin")
      result = shell_out("chef-client -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end
  end
end
