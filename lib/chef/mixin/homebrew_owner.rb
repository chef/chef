#
# Author:: Joshua Timberman (<joshua@getchef.com>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright 2011-2013, Opscode, Inc.
# Copyright 2014, Chef Software, Inc <legal@getchef.com>
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
# Ported from the homebrew cookbook's Homebrew::Mixin owner helpers
#
# This lives here in Chef::Mixin because Chef's namespacing makes it
# awkward to use modules elsewhere (e.g., chef/provider/package/homebrew/owner)

class Chef
  module Mixin
    module HomebrewOwner
      def homebrew_owner(node)
        @homebrew_owner ||= calculate_owner(node)
      end

      private

      def calculate_owner(node)
        owner = homebrew_owner_attr(node) || sudo_user || current_user
        if owner == 'root'
          raise Chef::Exceptions::CannotDetermineHomebrewOwner,
            'The homebrew owner is not specified and the current user is \"root\"' +
            'Homebrew does not support root installs, please specify the homebrew' +
            'owner by setting the attribute `node[\'homebrew\'][\'owner\']`.'
        end
        owner
      end

      def homebrew_owner_attr(node)
        node['homebrew']['owner'] if node.attribute?('homebrew') && node['homebrew'].attribute?('owner')
      end

      def sudo_user
        ENV['SUDO_USER']
      end

      def current_user
        ENV['USER']
      end
    end
  end
end
