class Chef
  class Dist
    # This class is not fully implemented, depending on it is not recommended!
    # When referencing a product directly, like Chef (Now Chef Infra)
    PRODUCT = "Chef Infra Client".freeze

    # The name of the server product
    SERVER_PRODUCT = "Chef Infra Server".freeze

    # The client's alias (chef-client)
    CLIENT = "chef-client".freeze

    # name of the automate product
    AUTOMATE = "Chef Automate".freeze

    # The chef executable, as in `chef gem install` or `chef generate cookbook`
    EXEC = "chef".freeze

    # product website address
    WEBSITE = "https://chef.io".freeze

    # Chef-Zero's product name
    ZERO = "Chef Infra Zero".freeze

    # Chef-Solo's product name
    SOLO = "Chef Infra Solo".freeze

    # The chef-zero executable (local mode)
    ZEROEXEC = "chef-zero".freeze

    # The chef-solo executable (legacy local mode)
    SOLOEXEC = "chef-solo".freeze

    # The chef-shell executable
    SHELL = "chef-shell".freeze

    # Configuration related constants
    # The chef-shell configuration file
    SHELL_CONF = "chef_shell.rb".freeze

    # The configuration directory
    CONF_DIR = "/etc/#{Chef::Dist::EXEC}".freeze

    # The user's configuration directory
    USER_CONF_DIR = ".chef".freeze

    # The server's configuration directory
    SERVER_CONF_DIR = "/etc/chef-server".freeze
  end
end
