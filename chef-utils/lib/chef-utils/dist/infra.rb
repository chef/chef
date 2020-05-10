module ChefUtils
  module Dist
    class Infra
      # When referencing a product directly, as in "Chef Infra"
      PRODUCT = "Chef Infra Client".freeze

      # The chef-main-wrapper executable name.
      EXEC = "chef".freeze

      # The client's alias (chef-client)
      CLIENT = "chef-client".freeze

      # A short name for the product
      SHORT = "chef".freeze

      # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
      # "cinc" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "chef".freeze

      # The user's configuration directory
      USER_CONF_DIR = ".chef".freeze

      # chef-shell executable
      SHELL = "chef-shell".freeze

      # The chef-shell default configuration file
      SHELL_CONF ="chef_shell.rb".freeze

      # chef-zero executable
      ZERO = "Chef Infra Zero".freeze

      # Chef-Solo's product name
      SOLO = "Chef Infra Solo".freeze

      # The chef-zero executable (local mode)
      ZEROEXEC = "chef-zero".freeze

      # The chef-solo executable (legacy local mode)
      SOLOEXEC = "chef-solo".freeze
    end
  end
end
