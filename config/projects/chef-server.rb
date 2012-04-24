name "chef-server"

replaces        "chef-server"
install_path    "/opt/chef-server"
build_version   Omnibus::BuildVersion.full
build_iteration "1"

# initialize the dependencies
dependencies %w{
preparation
chef-server
chef-server-cookbooks
version-manifest
}

exclude "\.git*"
exclude "bundler\/git"
