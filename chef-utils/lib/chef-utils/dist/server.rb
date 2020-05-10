module ChefUtils
  module Dist
    class Server
      # The name of the server product
      PRODUCT = "Chef Infra Server".freeze

      # Assumed location of the chef-server configuration directory
      # TODO: This actually sounds like a job for ChefUtils methods
      CONF_DIR = "/etc/chef-server".freeze
    end
  end
end
