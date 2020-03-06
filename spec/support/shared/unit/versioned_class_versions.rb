class VersionedClassV0
  extend Chef::Mixin::VersionedAPI
  minimum_api_version 0
end

class VersionedClassV2
  extend Chef::Mixin::VersionedAPI
  minimum_api_version 2
end

class VersionedClassVersions
  extend Chef::Mixin::VersionedAPIFactory
  add_versioned_api_class VersionedClassV0
  add_versioned_api_class VersionedClassV2
end

# before do
#   Chef::ServerAPIVersions.instance.reset!
# end
