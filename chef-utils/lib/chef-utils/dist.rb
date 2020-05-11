module ChefUtils
  module Dist
    class Apply
      # The chef-apply product name
      PRODUCT = "Chef Infra Apply".freeze
      # The chef-apply binary
      EXEC = "chef-apply".freeze
    end
    class Automate
      PRODUCT = "Chef Automate".freeze
    end
    class Compliance
      PRODUCT = "Chef Compliance".freeze
    end
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
      # "chef" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "chef".freeze

      # The user's configuration directory
      USER_CONF_DIR = ".chef".freeze

      # chef-shell executable
      SHELL = "chef-shell".freeze

      # The chef-shell default configuration file
      SHELL_CONF = "chef_shell.rb".freeze
    end
    class Inspec
      PRODUCT = "Chef Inspec".freeze

      EXEC = "inspec".freeze

      DIR_SUFFIX = "inspec".freeze
    end
    class Org
      # Main Website address
      WEBSITE = "https://chef.io".freeze

      # The downloads site
      DOWNLOADS_URL = "downloads.chef.io".freeze

      # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
      # DIR_SUFFIX is appended to it in code where relevant
      LEGACY_CONF_DIR = "opscode".freeze
    end
    class Run
      # chef-run's product name
      PRODUCT = "Chef Infra Run".freeze

      # The chef-run binary
      EXEC = "chef-run".freeze
    end
    class Server
      # The name of the server product
      PRODUCT = "Chef Infra Server".freeze

      # Assumed location of the chef-server configuration directory
      # TODO: This actually sounds like a job for ChefUtils methods
      CONF_DIR = "/etc/chef-server".freeze
    end
    class Solo
      # Chef-Solo's product name
      PRODUCT = "Chef Infra Solo".freeze

      # The chef-solo executable (legacy local mode)
      EXEC = "chef-solo".freeze
    end
    class Workstation
      # The Workstation's product name
      PRODUCT = "Chef Workstation".freeze

      # The old ChefDK product name
      DK = "ChefDK".freeze

      # The suffix for workstation's eponymous folders, like /opt/workstation
      DIR_SUFFIX = "chef-workstation".freeze

      # The suffix for ChefDK's eponymous folders, like /opt/chef-dk
      LEGACY_DIR_SUFFIX = "chef-dk".freeze
    end
    class Zero
      # chef-zero executable
      PRODUCT = "Chef Infra Zero".freeze

      # The chef-zero executable (local mode)
      EXEC = "chef-zero".freeze
    end
  end
end
