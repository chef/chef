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

    # The legacy conf folder: C:/opscode/chef. Specifically the "opscode" part
    # DIR_SUFFIX is appended to it in code where relevant
    LEGACY_CONF_DIR = "opscode".freeze

    # Enable forcing Chef EULA
    ENFORCE_LICENSE = true
  end
end
