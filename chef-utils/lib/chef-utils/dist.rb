# frozen_string_literal: true
module ChefUtils
  # This class is not fully implemented, depending on it is not recommended!
  module Dist
    class Apply
      # The chef-apply product name
      PRODUCT = "Chef Infra Apply"

      # The chef-apply binary
      EXEC = "chef-apply"
    end

    class Automate
      # name of the automate product
      PRODUCT = "Chef Automate"
    end

    class Cli
      # the chef-cli product name
      PRODUCT = "Chef CLI"

      # the chef-cli gem
      GEM = "chef-cli"
    end

    class Habitat
      # name of the Habitat product
      PRODUCT = "Chef Habitat"

      # A short designation for the product
      SHORT = "habitat"

      # The hab cli binary
      EXEC = "hab"
    end

    class Infra
      # When referencing a product directly, like Chef (Now Chef Infra)
      PRODUCT = "Chef Infra Client"

      # A short designation for the product, used in Windows event logs
      # and some nomenclature.
      SHORT = "chef"

      # The client's alias (chef-client)
      CLIENT = "chef-client"

      # The chef executable, as in `chef gem install` or `chef generate cookbook`
      EXEC = "chef"

      # The chef-shell executable
      SHELL = "chef-shell"

      # Configuration related constants
      # The chef-shell configuration file
      SHELL_CONF = "chef_shell.rb"

      # The user's configuration directory
      USER_CONF_DIR = ".chef"

      # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
      # "chef" => /etc/cinc, /var/cinc, C:\\cinc
      DIR_SUFFIX = "chef"

      # The client's gem
      GEM = "chef"
    end

    class Inspec
      # The InSpec product name
      PRODUCT = "Chef InSpec"

      # The inspec binary
      EXEC = "inspec"
    end

    class Org
      # product Website address
      WEBSITE = "https://chef.io"

      # The downloads site
      DOWNLOADS_URL = "downloads.chef.io"

      # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
      # DIR_SUFFIX is appended to it in code where relevant
      LEGACY_CONF_DIR = "opscode"

      # Enable forcing Chef EULA
      ENFORCE_LICENSE = true

      # product patents page
      PATENTS = "https://www.chef.io/patents"

      # knife documentation page
      KNIFE_DOCS = "https://docs.chef.io/workstation/knife/"

      # the name of the overall infra product
      PRODUCT = "Chef Infra"
    end

    class Server
      # The name of the server product
      PRODUCT = "Chef Infra Server"

      # The server's configuration directory
      CONF_DIR = "/etc/chef-server"

      # The servers's alias (chef-server)
      SERVER = "chef-server"

      # The server's configuration utility
      SERVER_CTL = "chef-server-ctl"
    end

    class Solo
      # Chef-Solo's product name
      PRODUCT = "Chef Infra Solo"

      # The chef-solo executable (legacy local mode)
      EXEC = "chef-solo"
    end

    class Workstation
      # The full marketing name of the product
      PRODUCT = "Chef Workstation"

      # The suffix for Chef Workstation's /opt/chef-workstation or C:\\opscode\chef-workstation
      DIR_SUFFIX = "chef-workstation"

      # Workstation banner/help text
      DOCS = "https://docs.chef.io/workstation/"
    end

    class Zero
      # chef-zero executable
      PRODUCT = "Chef Infra Zero"

      # The chef-zero executable (local mode)
      EXEC = "chef-zero"
    end
  end
end
