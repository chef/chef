#
# Cookbook:: base
# Recipe:: docker
#
# Copyright:: 2018, Chef Software, Inc.
#

docker_service "default" do
  action [:create, :start]
end

docker_image "busybox" do
  host "unix:///var/run/docker.sock"
end

docker_volume "hello" do
  action :create
end

docker_network "network_a" do
  action :create
end

docker_container "service default echo server" do
  container_name "an_echo_server"
  repo "busybox"
  volumes ["hello:/hello"]
  network_mode "network_a"
  command "nc -ll -p 7 -e /bin/cat"
  port "7"
  action :run
end
