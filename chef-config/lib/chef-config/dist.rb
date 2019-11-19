module ChefConfig
  class Dist
    # The chef executable name. Also used in directory names.
    EXEC = "chef".freeze

    # The suffix for Chef's /etc/chef, /var/chef and C:\\Chef directories
    # "cinc" => /etc/cinc, /var/cinc, C:\\cinc
    DIR_SUFFIX = "chef".freeze
  end
end
