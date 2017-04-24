require "chef/cookbook_manifest/manifest_v0"
require "chef/cookbook_manifest/manifest_v2"

class Chef
  class CookbookManifest
    class Versions

      extend Chef::Mixin::VersionedAPIFactory
      add_versioned_api_class Chef::CookbookManifest::ManifestV0
      add_versioned_api_class Chef::CookbookManifest::ManifestV2

      def_versioned_delegator :from_hash
      def_versioned_delegator :to_hash
    end
  end
end
