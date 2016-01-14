# Shamelessly copied from https://github.com/onehealth-cookbooks/apache2/blob/master/test/fixtures/serverspec_helper.rb
# The commented-out platforms in the osmapping hash can be added once we have added them into
# our .kitchen.yml and .kitchen.travis.yml and added the appropriate JSON under test/fixtures/platforms.

require "serverspec"
require "json"
require "ffi_yajl"

set :backend, :exec

include Specinfra::Helper::Properties

require "pp"
pp os

def load_nodestub
  case os[:family]
  when "ubuntu", "debian"
    platform = os[:family]
    platform_version = os[:release]
  when "redhat"
    platform = "centos"
    platform_version = os[:release].to_i
  end
  FFI_Yajl::Parser.parse(IO.read("#{ENV['BUSSER_ROOT']}/../kitchen/data/platforms/#{platform}/#{platform_version}.json"), :symbolize_names => true)
end

# centos-59 doesn't have /sbin in the default path,
# so we must ensure it's on serverspec's path
set :path, "$PATH:/sbin"

set_property load_nodestub
