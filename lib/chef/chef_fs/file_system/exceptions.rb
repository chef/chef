#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

class Chef
  module ChefFS
    module FileSystem
      class FileSystemError < StandardError
        # @param entry The entry which had an issue.
        # @param cause The wrapped exception (if any).
        # @param reason A string describing why this exception happened.
        def initialize(entry, cause = nil, reason = nil)
          super(reason)
          @entry = entry
          @cause = cause
          @reason = reason
        end

        # The entry which had an issue.
        attr_reader :entry

        # The wrapped exception (if any).
        attr_reader :cause

        # A string describing why this exception happened.
        attr_reader :reason
      end

      class MustDeleteRecursivelyError < FileSystemError; end

      class NotFoundError < FileSystemError; end

      class OperationFailedError < FileSystemError
        def initialize(operation, entry, cause = nil, reason = nil)
          super(entry, cause, reason)
          @operation = operation
        end

        def message
          if cause && cause.is_a?(Net::HTTPExceptions) && cause.response.code == "400"
            "#{super} cause: #{cause.response.body}"
          else
            super
          end
        end

        attr_reader :operation
      end

      class OperationNotAllowedError < FileSystemError
        def initialize(operation, entry, cause = nil, reason = nil)
          reason ||=
            case operation
            when :delete
              "cannot be deleted"
            when :write
              "cannot be updated"
            when :create_child
              "cannot have a child created under it"
            when :read
              "cannot be read"
            end
          super(entry, cause, reason)
          @operation = operation
        end

        attr_reader :operation
        attr_reader :entry
      end

      class AlreadyExistsError < OperationFailedError; end

      class CookbookFrozenError < AlreadyExistsError; end

      class RubyFileError < OperationNotAllowedError
        def reason
          result = super
          result + " (can't safely update ruby files)"
        end
      end

      class DefaultEnvironmentCannotBeModifiedError < OperationNotAllowedError
        def reason
          result = super
          result + " (default environment cannot be modified)"
        end
      end

    end
  end
end
