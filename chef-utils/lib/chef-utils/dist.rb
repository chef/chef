module ChefUtils
  # This class is not fully implemented, depending on it is not recommended!
  module Dist
    class Apply
      # The chef-apply product name
      PRODUCT = "Chef Infra Apply".freeze

      # The chef-apply binary
      EXEC = "chef-apply".freeze
    end

    class Automate
      # name of the automate product
      PRODUCT = "Chef Automate".freeze
    end

    class Infra
      # When referencing a product directly, like Chef (Now Chef Infra)
      PRODUCT = "Chef Infra Client".freeze

      # A short designation for the product, used in Windows event logs
      # and some nomenclature.
      SHORT = "chef".freeze

      # The client's alias (chef-client)
      CLIENT = "chef-client".freeze

      # The chef executable, as in `chef gem install` or `chef generate cookbook`
      EXEC = "chef".freeze

      # The chef-shell executable
      SHELL = "chef-shell".freeze

      # Configuration related constants
      # The chef-shell configuration file
      SHELL_CONF = "chef_shell.rb".freeze

      # The user's configuration directory
      USER_CONF_DIR = ".chef".freeze

      # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
      # "chef" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "chef".freeze
    end

    class Org
      # product Website address
      WEBSITE = "https://chef.io".freeze

      # The downloads site
      DOWNLOADS_URL = "downloads.chef.io".freeze

      # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
      # DIR_SUFFIX is appended to it in code where relevant
      LEGACY_CONF_DIR = "opscode".freeze

      # Enable forcing Chef EULA
      ENFORCE_LICENSE = true

      # product patents page
      PATENTS = "https://www.chef.io/patents".freeze

      # knife documentation page
      KNIFE_DOCS = "https://docs.chef.io/workstation/knife/".freeze
    end

    class Server
      # The name of the server product
      PRODUCT = "Chef Infra Server".freeze

      # The server's configuration directory
      CONF_DIR = "/etc/chef-server".freeze

      # The servers's alias (chef-server)
      SERVER = "chef-server".freeze

      # The server's configuration utility
      SERVER_CTL = "chef-server-ctl".freeze
    end

    class Solo
      # Chef-Solo's product name
      PRODUCT = "Chef Infra Solo".freeze

      # The chef-solo executable (legacy local mode)
      EXEC = "chef-solo".freeze
    end

    class Zero
      # chef-zero executable
      PRODUCT = "Chef Infra Zero".freeze

      # The chef-zero executable (local mode)
      EXEC = "chef-zero".freeze
    end
  end
end
