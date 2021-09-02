apt_update

habitat_install "default" do
  license "accept"
end

habitat_package "core/redis"

habitat_package "lamont-granquist/ruby" do
  channel "unstable"
  version "2.3.1"
end

habitat_package "core/bundler" do
  channel "unstable"
  version "1.13.3/20161011123917"
end

habitat_package "core/htop" do
  options "--binlink"
end

habitat_package "core/hab-sup" do
  bldr_url "https://bldr.habitat.sh"
end

habitat_package "binlink" do
  package_name "core/nginx"
  version "1.15.2"
  binlink true
end

habitat_package "binlink_force" do
  package_name "core/nginx"
  version "1.15.6/20181212185120"
  binlink :force
end

habitat_package "core/nginx" do
  action :remove
end
