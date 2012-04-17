name "chef-server"

replaces        "chef-server"
install_path    "/opt/chef-server"
build_version   Omnibus::BuildVersion.full
build_iteration "1"

# initialize the dependencies
deps = []

# global
deps << "chef"
deps << "nginx"
deps << "runit"
deps << "unicorn"
deps << "couchdb"
deps << "rabbitmq"

# Version manifest file
deps << "pc-version"

dependencies deps

exclude "\.git*"
exclude "bundler\/git"
