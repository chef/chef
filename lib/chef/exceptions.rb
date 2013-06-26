#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright 2008-2010 Opscode, Inc.
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

class Chef
  # == Chef::Exceptions
  # Chef's custom exceptions are all contained within the Chef::Exceptions
  # namespace.
  class Exceptions

    # Backcompat with Chef::ShellOut code:
    require 'mixlib/shellout/exceptions'

    def self.const_missing(const_name)
      if const_name == :ShellCommandFailed
        Chef::Log.warn("Chef::Exceptions::ShellCommandFailed is deprecated, use Mixlib::ShellOut::ShellCommandFailed")
        called_from = caller[0..3].inject("Called from:\n") {|msg, trace_line| msg << "  #{trace_line}\n" }
        Chef::Log.warn(called_from)
        Mixlib::ShellOut::ShellCommandFailed
      else
        super
      end
    end

    class Application < RuntimeError; end
    class Cron < RuntimeError; end
    class Env < RuntimeError; end
    class Exec < RuntimeError; end
    class ErlCall < RuntimeError; end
    class FileNotFound < RuntimeError; end
    class Package < RuntimeError; end
    class Service < RuntimeError; end
    class Route < RuntimeError; end
    class SearchIndex < RuntimeError; end
    class Override < RuntimeError; end
    class UnsupportedAction < RuntimeError; end
    class MissingLibrary < RuntimeError; end
    class CannotDetermineNodeName < RuntimeError; end
    class User < RuntimeError; end
    class Group < RuntimeError; end
    class Link < RuntimeError; end
    class Mount < RuntimeError; end
    class PrivateKeyMissing < RuntimeError; end
    class CannotWritePrivateKey < RuntimeError; end
    class RoleNotFound < RuntimeError; end
    class ValidationFailed < ArgumentError; end
    class InvalidPrivateKey < ArgumentError; end
    class ConfigurationError < ArgumentError; end
    class RedirectLimitExceeded < RuntimeError; end
    class AmbiguousRunlistSpecification < ArgumentError; end
    class CookbookFrozen < ArgumentError; end
    class CookbookNotFound < RuntimeError; end
    # Cookbook loader used to raise an argument error when cookbook not found.
    # for back compat, need to raise an error that inherits from ArgumentError
    class CookbookNotFoundInRepo < ArgumentError; end
    class RecipeNotFound < ArgumentError; end
    class AttributeNotFound < RuntimeError; end
    class InvalidCommandOption < RuntimeError; end
    class CommandTimeout < RuntimeError; end
    class RequestedUIDUnavailable < RuntimeError; end
    class InvalidHomeDirectory < ArgumentError; end
    class DsclCommandFailed < RuntimeError; end
    class UserIDNotFound < ArgumentError; end
    class GroupIDNotFound < ArgumentError; end
    class InvalidResourceReference < RuntimeError; end
    class ResourceNotFound < RuntimeError; end
    class InvalidResourceSpecification < ArgumentError; end
    class SolrConnectionError < RuntimeError; end
    class IllegalChecksumRevert < RuntimeError; end
    class CookbookVersionNameMismatch < ArgumentError; end
    class MissingParentDirectory < RuntimeError; end
    class UnresolvableGitReference < RuntimeError; end
    class InvalidRemoteGitReference < RuntimeError; end
    class InvalidEnvironmentRunListSpecification < ArgumentError; end
    class InvalidDataBagItemID < ArgumentError; end
    class InvalidDataBagName < ArgumentError; end
    class EnclosingDirectoryDoesNotExist < ArgumentError; end
    # Errors originating from calls to the Win32 API
    class Win32APIError < RuntimeError; end
    # Thrown when Win32 API layer binds to non-existent Win32 function.  Occurs
    # when older versions of Windows don't support newer Win32 API functions.
    class Win32APIFunctionNotImplemented < NotImplementedError; end
    # Attempting to run windows code on a not-windows node
    class Win32NotWindows < RuntimeError; end
    class WindowsNotAdmin < RuntimeError; end
    # Attempting to access a 64-bit only resource on a 32-bit Windows system
    class Win32ArchitectureIncorrect < RuntimeError; end
    class ObsoleteDependencySyntax < ArgumentError; end
    class InvalidDataBagPath < ArgumentError; end

    # A different version of a cookbook was added to a
    # VersionedRecipeList than the one already there.
    class CookbookVersionConflict < ArgumentError ; end

    # does not follow X.Y.Z format. ArgumentError?
    class InvalidPlatformVersion < ArgumentError; end
    class InvalidCookbookVersion < ArgumentError; end

    # version constraint should be a string or array, or it doesn't
    # match OP VERSION. ArgumentError?
    class InvalidVersionConstraint < ArgumentError; end

    # Version constraints are not allowed in chef-solo
    class IllegalVersionConstraint < NotImplementedError; end

    # File operation attempted but no permissions to perform it
    class InsufficientPermissions < RuntimeError; end

    # Ifconfig failed
    class Ifconfig < RuntimeError; end

    # Invalid "source" parameter to a remote_file resource
    class InvalidRemoteFileURI < ArgumentError; end

    # Node::Attribute computes the merged version of of attributes
    # and makes it read-only. Attempting to modify a read-only
    # attribute will cause this error.
    class ImmutableAttributeModification < NoMethodError; end

    # Merged node attributes are invalidated when the component
    # attributes are updated. Attempting to read from a stale copy
    # of merged attributes will trigger this error.
    class StaleAttributeRead < StandardError; end

    # Registry Helper throws the following errors
    class Win32RegArchitectureIncorrect < Win32ArchitectureIncorrect; end
    class Win32RegHiveMissing < ArgumentError; end
    class Win32RegKeyMissing < RuntimeError; end
    class Win32RegValueMissing < RuntimeError; end
    class Win32RegDataMissing < RuntimeError; end
    class Win32RegValueExists < RuntimeError; end
    class Win32RegNoRecursive < ArgumentError; end
    class Win32RegTypeDoesNotExist < ArgumentError; end
    class Win32RegBadType < ArgumentError; end
    class Win32RegBadValueSize < ArgumentError; end
    class Win32RegTypesMismatch < ArgumentError; end

    class InvalidEnvironmentPath < ArgumentError; end
    class EnvironmentNotFound < RuntimeError; end

    # File-like resource found a non-file (socket, pipe, directory, etc) at its destination
    class FileTypeMismatch < RuntimeError; end

    # File (or descendent) resource configured to manage symlink source, but
    # the symlink that is there either loops or points to a nonexistent file
    class InvalidSymlink < RuntimeError; end

    class MissingRole < RuntimeError
      NULL = Object.new

      attr_reader :expansion

      def initialize(message_or_expansion=NULL)
        @expansion = nil
        case message_or_expansion
        when NULL
          super()
        when String
          super
        when RunList::RunListExpansion
          @expansion = message_or_expansion
          missing_roles = @expansion.errors.join(', ')
          super("The expanded run list includes nonexistent roles: #{missing_roles}")
        end
      end


    end
    # Exception class for collecting multiple failures. Used when running
    # delayed notifications so that chef can process each delayed
    # notification even if chef client or other notifications fail.
    class MultipleFailures < StandardError
      def initialize(*args)
        super
        @all_failures = []
      end

      def message
        base = "Multiple failures occurred:\n"
        @all_failures.inject(base) do |message, (location, error)|
          message << "* #{error.class} occurred in #{location}: #{error.message}\n"
        end
      end

      def client_run_failure(exception)
        set_backtrace(exception.backtrace)
        @all_failures << [ "chef run", exception ]
      end

      def notification_failure(exception)
        @all_failures << [ "delayed notification", exception ]
      end

      def raise!
        unless empty?
          raise self.for_raise
        end
      end

      def empty?
        @all_failures.empty?
      end

      def for_raise
        if @all_failures.size == 1
          @all_failures[0][1]
        else
          self
        end
      end
    end

    class CookbookVersionSelection

      # Compound exception: In run_list expansion and resolution,
      # run_list items referred to cookbooks that don't exist and/or
      # have no versions available.
      class InvalidRunListItems < StandardError
        attr_reader :non_existent_cookbooks
        attr_reader :cookbooks_with_no_matching_versions

        def initialize(message, non_existent_cookbooks, cookbooks_with_no_matching_versions)
          super(message)

          @non_existent_cookbooks = non_existent_cookbooks
          @cookbooks_with_no_matching_versions = cookbooks_with_no_matching_versions
        end

        def to_json(*a)
          result = {
            "message" => message,
            "non_existent_cookbooks" => non_existent_cookbooks,
            "cookbooks_with_no_versions" => cookbooks_with_no_matching_versions
          }
          result.to_json(*a)
        end
      end

      # In run_list expansion and resolution, a constraint was
      # unsatisfiable.
      #
      # This exception may not be the complete error report. If you
      # resolve the misconfiguration represented by this exception and
      # re-solve, you may get another exception
      class UnsatisfiableRunListItem < StandardError
        attr_reader :run_list_item
        attr_reader :non_existent_cookbooks, :most_constrained_cookbooks

        # most_constrained_cookbooks: if I were to remove constraints
        # regarding these cookbooks, I would get a solution or move on
        # to the next error (deeper in the graph). An item in this list
        # may be unsatisfiable, but when resolved may also reveal
        # further unsatisfiable constraints; this condition would not be
        # reported.
        def initialize(message, run_list_item, non_existent_cookbooks, most_constrained_cookbooks)
          super(message)

          @run_list_item = run_list_item
          @non_existent_cookbooks = non_existent_cookbooks
          @most_constrained_cookbooks = most_constrained_cookbooks
        end

        def to_json(*a)
          result = {
            "message" => message,
            "unsatisfiable_run_list_item" => run_list_item,
            "non_existent_cookbooks" => non_existent_cookbooks,
            "most_constrained_cookbooks" => most_constrained_cookbooks
          }
          result.to_json(*a)
        end
      end

    end # CookbookVersionSelection

    # When the server sends a redirect, RFC 2616 states a user-agent should
    # not follow it with a method other than GET or HEAD, unless a specific
    # action is taken by the user. A redirect received as response to a
    # non-GET and non-HEAD request will thus raise an InvalidRedirect.
    class InvalidRedirect < StandardError; end

  end
end
