name "chef-server"

replaces        "chef-server"
install_path    "/opt/chef-server"
build_version   Omnibus::BuildVersion.full
build_iteration "1"

deps = []

# global
deps << "chef"
deps << "preparation"
deps << "chef-server-ctl"
deps << "nginx"
deps << "runit"
deps << "unicorn"

# the backend
deps << "couchdb"
deps << "rabbitmq"
deps << "chef-solr"
deps << "chef-expander"

# the front-end services
deps << "chef-server-api"
deps << "chef-server-webui"

# version manifest file
deps << "version-manifest"

dependencies deps

exclude "\.git*"
exclude "bundler\/git"
