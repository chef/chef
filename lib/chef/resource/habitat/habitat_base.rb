
require_relative "../../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class HabitatBase < Chef::Resource
      property :bldr_url, String, default: node["habitat"]["bldr_url"] || "https://bldr.habitat.sh",
      description: "The habitat builder url where packages will be downloaded from. **Defaults to public Habitat Builder**"

      property :channel, String, default: node["habitat"]["channel"] || "stable",
      description: "The release channel to install your package from."

      property :auth_token, String, default: node["habitat"]["auth_token"] || Nil,
      description: "Auth token for installing a package."

      action_class do
        use "habitat_shared"
      end
    end
  end
end
