# TODO: habitat_install Windows kitchen test temporarily commented out while
# ffi-libarchive/archive.dll loading issue with ruby3_4-plus-devkit/3.4.10
# is being resolved in https://github.com/chef/chef/pull/16242
# habitat_install "default" do
#   license "accept"
# end

habitat_package "chef/splunkforwarder" do
  version "7.0.3/20250714155325"
end
