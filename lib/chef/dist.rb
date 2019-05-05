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
    AUTOMATE = "Chef Automate"

    # The chef executable, as in `chef gem install` or `chef generate cookbook`
    EXEC = "chef".freeze

    # product website address
    WEBSITE = "https://chef.io".freeze

    # Chef-Zero's product name
    ZERO = "Chef Infra Zero"

    # Chef-Solo's product name
    SOLO = "Chef Infra Solo"

    # The chef-zero executable (local mode)
    ZEROEXEC = "chef-zero"

    # The chef-solo executable (legacy local mode)
    SOLOEXEC = "chef-solo"
  end
end
