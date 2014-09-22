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

require 'chef/mixin/shell_out'
require 'etc'

class Chef
  module Mixin
    module HomebrewUser
      include Chef::Mixin::ShellOut

      ##
      # This tries to find the user to execute brew as.  If a user is provided, that overrides the brew
      # executable user.  It is an error condition if the brew executable owner is root or we cannot find
      # the brew executable.
      def find_homebrew_uid(provided_user)
        # They could provide us a user name or a UID
        unless provided_user.nil?
          return provided_user if provided_user.is_a? Integer
          return Etc.getpwnam(provided_user).uid
        end

        @homebrew_owner ||= calculate_owner
        if @homebrew_owner == 0
          raise Chef::Exceptions::HomebrewOwnerIsRoot,
                'The homebrew owner is currently "root".  This is not suggested by the' +
                    'homebrew maintainers.'
        end
        @homebrew_owner
      end

      private

      def calculate_owner
        default_brew_path = '/usr/local/bin/brew'
        if ::File.exist?(default_brew_path)
          # By default, this follows symlinks which is what we want
          ::File.stat(default_brew_path).uid
        elsif (brew_path = shell_out("which brew").stdout.strip) && !brew_path.empty?
          ::File.stat(brew_path).uid
        else
          raise Chef::Exceptions::CannotDetermineHomebrewOwner,
                'Could not find the "brew" executable in /usr/local/bin or anywhere on the ' +
                    'path.'
        end
      end

    end
  end
end
