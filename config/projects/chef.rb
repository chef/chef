name "chef"

replaces        "chef-full"
install_path    "/opt/chef"
build_version   Omnibus::BuildVersion.full
build_iteration "4"

dependencies ["preparation","chef","version-manifest"]

