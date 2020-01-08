module ChefConfig
  class Dist
    # The chef executable name.
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
  end
end
