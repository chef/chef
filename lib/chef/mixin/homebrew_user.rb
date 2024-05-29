#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "shell_out"
require "etc" unless defined?(Etc)

class Chef
  module Mixin
    module HomebrewUser
      include Chef::Mixin::ShellOut

      ##
      # This tries to find the user to execute brew as.  If a user is provided, that overrides the brew
      # executable user.  It is an error condition if the brew executable owner is root or we cannot find
      # the brew executable.
      # @param [String, Integer] provided_user
      # @return [Integer] UID of the user
      def find_homebrew_uid(provided_user = nil)
        # They could provide us a user name or a UID
        if provided_user
          return provided_user if provided_user.is_a? Integer

          return Etc.getpwnam(provided_user).uid
        end

        @homebrew_owner_uid ||= calculate_owner
        @homebrew_owner_uid
      end

      # Use find_homebrew_uid to return the UID and then lookup the
      # name from that UID because sometimes you want the name not the UID
      # @param [String, Integer] provided_user
      # @return [String] username
      def find_homebrew_username(provided_user = nil)
        @homebrew_owner_username ||= Etc.getpwuid(find_homebrew_uid(provided_user)).name
        @homebrew_owner_username
      end

      def homebrew_bin_path(brew_bin_path = nil)
        if brew_bin_path && ::File.exist?(brew_bin_path)
          brew_bin_path
        else
          [which("brew"), "/opt/homebrew/bin/brew", "/usr/local/bin/brew", "/home/linuxbrew/.linuxbrew/bin/brew"].uniq.select do |x|
            next if x == false

            ::File.exist?(x) && ::File.executable?(x)
          end.first || nil
        end
      end

      private

      def calculate_owner
        brew_path = homebrew_bin_path
        if brew_path
          # By default, this follows symlinks which is what we want
          owner = ::File.stat(brew_path).uid
        else
          raise Chef::Exceptions::CannotDetermineHomebrewOwner,
            'Couldn\'t find the "brew" executable anywhere on the path.'
        end

        Chef::Log.debug "Found Homebrew owner #{Etc.getpwuid(owner).name}; executing `brew` commands as them"
        owner
      end

    end
  end
end
