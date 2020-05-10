module ChefUtils
  module Dist
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
  end
end
