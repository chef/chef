module ChefConfig
  class Dist
    # The chef executable name. Also used in directory names.
    EXEC = "chef".freeze
    # The Chef configuration directory. It will be used by Chef's dist.rb.
    CONF_DIR = "/etc/#{ChefConfig::Dist::EXEC}".freeze
  end
end
