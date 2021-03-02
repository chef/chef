
class Chef
  class Knife
    KNIFE_ROOT = File.expand_path("../..", __dir__)
    # MPTD - under chef this a Chef::VersionString, but we can't use that here
    # without making a circular dep. We should probalby move VersionString to into ChefUtil?
    # MPTD - this should be getting auto-updated
    VERSION = "17.0.132".freeze
  end
end


