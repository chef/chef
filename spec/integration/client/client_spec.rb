require 'support/shared/integration/integration_helper'
require 'chef/mixin/shell_out'

describe "chef-client" do
  include IntegrationSupport
  include Chef::Mixin::ShellOut

  let(:chef_dir) { File.join(File.dirname(__FILE__), "..", "..", "..", "bin") }

  # Invoke `chef-client` as `ruby PATH/TO/chef-client`. This ensures the
  # following constraints are satisfied:
  # * Windows: windows can only run batch scripts as bare executables. Rubygems
  # creates batch wrappers for installed gems, but we don't have batch wrappers
  # in the source tree.
  # * Other `chef-client` in PATH: A common case is running the tests on a
  # machine that has omnibus chef installed. In that case we need to ensure
  # we're running `chef-client` from the source tree and not the external one.
  # cf. CHEF-4914
  let(:chef_client) { "ruby '#{chef_dir}/chef-client'" }

  when_the_repository "has a cookbook with a no-op recipe" do
    before { file 'cookbooks/x/recipes/default.rb', '' }

    it "should complete with success" do
      file 'config/client.rb', <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
      result.error!
    end

    context 'and no config file' do
      it 'should complete with success when cwd is just above cookbooks and paths are not specified' do
        result = shell_out("#{chef_client} -z -o 'x::default' --disable-config", :cwd => path_to(''))
        result.error!
      end

      it 'should complete with success when cwd is below cookbooks and paths are not specified' do
        result = shell_out("#{chef_client} -z -o 'x::default' --disable-config", :cwd => path_to('cookbooks/x'))
        result.error!
      end

      it 'should fail when cwd is below high above and paths are not specified' do
        result = shell_out("#{chef_client} -z -o 'x::default' --disable-config", :cwd => File.expand_path('..', path_to('')))
        result.exitstatus.should == 1
      end
    end

    context 'and a config file under .chef/knife.rb' do
      before { file '.chef/knife.rb', 'xxx.xxx' }

      it 'should load .chef/knife.rb when -z is specified' do
        result = shell_out("#{chef_client} -z -o 'x::default'", :cwd => path_to(''))
        # FATAL: Configuration error NoMethodError: undefined method `xxx' for nil:NilClass
        result.stdout.should include("xxx")
      end

    end

    it "should complete with success" do
      file 'config/client.rb', <<EOM
local_mode true
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
      result.error!
    end

    context 'and a private key' do
      before do
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
      end

      it "should complete with success even with a client key" do
        file 'config/client.rb', <<EOM
local_mode true
client_key #{path_to('mykey.pem').inspect}
cookbook_path #{path_to('cookbooks').inspect}
EOM

        result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default'", :cwd => chef_dir)
        result.error!
      end

      it "should run recipes specified directly on the command line" do
        file 'config/client.rb', <<EOM
local_mode true
client_key #{path_to('mykey.pem').inspect}
cookbook_path #{path_to('cookbooks').inspect}
EOM

        file 'arbitrary.rb', <<EOM
file #{path_to('tempfile.txt').inspect} do
  content '1'
end
EOM

        file 'arbitrary2.rb', <<EOM
file #{path_to('tempfile2.txt').inspect} do
  content '2'
end
EOM

        result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" #{path_to('arbitrary.rb')} #{path_to('arbitrary2.rb')}", :cwd => chef_dir)
        result.error!

        IO.read(path_to('tempfile.txt')).should == '1'
        IO.read(path_to('tempfile2.txt')).should == '2'
      end

      it "should run recipes specified as relative paths directly on the command line" do
        file 'config/client.rb', <<EOM
local_mode true
client_key #{path_to('mykey.pem').inspect}
cookbook_path #{path_to('cookbooks').inspect}
EOM

        file 'arbitrary.rb', <<EOM
file #{path_to('tempfile.txt').inspect} do
  content '1'
end
EOM

        result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" arbitrary.rb", :cwd => path_to(''))
        result.error!

        IO.read(path_to('tempfile.txt')).should == '1'
      end

      it "should run recipes specified directly on the command line AFTER recipes in the run list" do
        file 'config/client.rb', <<EOM
local_mode true
client_key #{path_to('mykey.pem').inspect}
cookbook_path #{path_to('cookbooks').inspect}
EOM

        file 'cookbooks/x/recipes/constant_definition.rb', <<EOM
class ::Blah
  THECONSTANT = '1'
end
EOM
        file 'arbitrary.rb', <<EOM
file #{path_to('tempfile.txt').inspect} do
  content ::Blah::THECONSTANT
end
EOM

        result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o x::constant_definition arbitrary.rb", :cwd => path_to(''))
        result.error!

        IO.read(path_to('tempfile.txt')).should == '1'
      end

    end

    it "should complete with success when passed the -z flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when passed the --local-mode flag" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default' --local-mode", :cwd => chef_dir)
      result.error!
    end

    it "should not print SSL warnings when running in local-mode" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default' --local-mode", :cwd => chef_dir)
      result.stdout.should_not include("SSL validation of HTTPS requests is disabled.")
      result.error!
    end

    it "should complete with success when passed -z and --chef-zero-port" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -o 'x::default' -z", :cwd => chef_dir)
      result.error!
    end

    it "should complete with success when setting the run list with -r" do
      file 'config/client.rb', <<EOM
chef_server_url 'http://omg.com/blah'
cookbook_path "#{path_to('cookbooks')}"
EOM

      result = shell_out("#{chef_client} -c \"#{path_to('config/client.rb')}\" -r 'x::default' -z", :cwd => chef_dir)
      result.stdout.should_not include("Overridden Run List")
      result.stdout.should include("Run List is [recipe[x::default]]")
      #puts result.stdout
      result.error!
    end

  end
end
