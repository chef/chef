#
# Cookbook:: end_to_end
# Recipe:: apt_preference
#

apt_preference "dotdeb" do
  glob         "*"
  pin          "origin packages.dotdeb.org"
  pin_priority "700"
end

apt_preference "libmysqlclient16" do
  action :remove
end