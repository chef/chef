class Chef
  class Dist
    # When referencing a product directly, like Chef (Now Chef Infra)
    PRODUCT = "Chef Infra".freeze

    # The client's alias (chef-client)
    CLIENT = "chef-client".freeze

    # the server tool's name (knife)
    KNIFE = "knife".freeze

    # Name used for certain directories. Merge with chef_executable?
    GENERIC = "chef".freeze

    # The chef executable, as in `chef gem install` or `chef generate cookbook`
    EXEC = "chef".freeze

    # product website address
    WEBSITE = "https://chef.io".freeze
  end
end
