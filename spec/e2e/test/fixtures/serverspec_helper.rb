# Shamelessly copied from opscode/onehealth-cookbooks/apache2/test/fixtures/serverspec_helper.rb
# The commented-out platforms in the osmapping hash can be added once we have added them into
# our .kitchen.yml and .kitchen.travis.yml and added the appropriate JSON under test/fixtures/platforms.

require 'serverspec'
require 'json'

include SpecInfra::Helper::Exec
include SpecInfra::Helper::DetectOS
include SpecInfra::Helper::Properties

# http://serverspec.org/advanced_tips.html
# os[:family]  # RedHat, Ubuntu, Debian and so on
# os[:release] # OS release version (cleaned up in v2)
# os[:arch]
osmapping = {
#   'RedHat' => {
#     :platform_family => 'rhel',
#     :platform => 'centos',
#     :platform_version => '6.5'
#   },
#   'RedHat7' => {
#     :platform_family => 'rhel',
#     :platform => 'centos',
#     :platform_version => '7.0'
#   },
#   'Fedora' => {
#     :platform_family => 'rhel',
#     :platform => 'fedora',
#     :platform_version => '20'
#   },
  'Ubuntu' => {
    :platform_family => 'debian',
    :platform => 'ubuntu',
    :platform_version => '12.04'
  }
#   'Debian' => {
#     :platform_family => 'debian',
#     :platform => 'debian',
#     :platform_version => '7.4'
#   },
#   'FreeBSD' => {
#     :platform_family => 'freebsd',
#     :platform => 'freebsd',
#     :platform_version => '9.2'
#   }
}

def ohai_platform(os, osmapping)
  puts "serverspec os detected as: #{os[:family]} #{os[:release]} [#{os[:arch]}]"
  ohaistub = {}
  ohaistub[:platform_family] = osmapping[os[:family]][:platform_family]
  ohaistub[:platform] = osmapping[os[:family]][:platform]
  if os[:release]
    ohaistub[:platform_version] = os[:release]
  else
    ohaistub[:platform_version] = osmapping[os[:family]][:platform_version]
  end
  ohaistub
end

def load_nodestub(ohai)
  puts "loading #{ohai[:platform]}/#{ohai[:platform_version]}"
  JSON.parse(IO.read("#{ENV['BUSSER_ROOT']}/../kitchen/data/platforms/#{ohai[:platform]}/#{ohai[:platform_version]}.json"), :symbolize_names => true)
end

RSpec.configure do |config|
  set_property load_nodestub(ohai_platform(backend.check_os, osmapping))
  config.before(:all) do
    # centos-59 doesn't have /sbin in the default path,
    # so we must ensure it's on serverspec's path
    config.path = '/sbin'
  end
end
