#--
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2010-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/mash"
require "chef/cookbook/gem_installer"

class Chef
  # == Chef::CookbookCollection
  # This class is the consistent interface for a node to obtain its
  # cookbooks by name.
  #
  # This class is basically a glorified Hash, but since there are
  # several ways this cookbook information is collected,
  # (e.g. CookbookLoader for solo, hash of auto-vivified Cookbook
  # objects for lazily-loaded remote cookbooks), it gets transformed
  # into this.
  class CookbookCollection < Mash

    # The input is a mapping of cookbook name to CookbookVersion objects. We
    # simply extract them
    def initialize(cookbook_versions = {})
      super() do |hash, key|
        raise Chef::Exceptions::CookbookNotFound, "Cookbook #{key} not found. " <<
          "If you're loading #{key} from another cookbook, make sure you configure the dependency in your metadata"
      end
      cookbook_versions.each { |cookbook_name, cookbook_version| self[cookbook_name] = cookbook_version }
    end

    # Validates that the cookbook metadata allows it to run on this instance.
    #
    # Currently checks chef_version and ohai_version in the cookbook metadata
    # against the running Chef::VERSION and Ohai::VERSION.
    #
    # @raises [Chef::Exceptions::CookbookChefVersionMismatch] if the Chef::VERSION fails validation
    # @raises [Chef::Exceptions::CookbookOhaiVersionMismatch] if the Ohai::VERSION fails validation
    def validate!
      each do |cookbook_name, cookbook_version|
        cookbook_version.metadata.validate_chef_version!
        cookbook_version.metadata.validate_ohai_version!
      end
    end

    def install_gems(events)
      Cookbook::GemInstaller.new(self, events).install
    end
  end
end
