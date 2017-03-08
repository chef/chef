#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc
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

require "chef/exceptions"
require "chef/guard_interpreter"
require "chef/mixin/descendants_tracker"

class Chef
  class Resource
    class File < Chef::Resource

      #
      # See RFC 027 for a full specification
      #
      # File verifications allow user-supplied commands a means of
      # preventing file resource content deploys.  Their intended use
      # is to verify the contents of a temporary file before it is
      # deployed onto the system.
      #
      # Similar to not_if and only_if, file verifications can take a
      # ruby block, which will be called, or a string, which will be
      # executed as a Shell command.
      #
      # Additonally, Chef or third-party verifications can ship
      # "registered verifications" that the user can use by specifying
      # a :symbol as the command name.
      #
      # To create a registered verification, create a class that
      # inherits from Chef::Resource::File::Verification and use the
      # provides class method to give it name.  Registered
      # verifications are expected to supply a verify instance method
      # that takes 2 arguments.
      #
      # Example:
      # class Chef
      #  class Resource
      #    class File::Verification::Foo < Chef::Resource::File::Verification
      #      provides :noop
      #      def verify(path, opts)
      #        #yolo
      #        true
      #      end
      #    end
      #  end
      # end
      #
      #

      class Verification
        extend Chef::Mixin::DescendantsTracker

        def self.provides(name)
          @provides = name
        end

        def self.provides?(name)
          @provides == name
        end

        def self.lookup(name)
          c = descendants.find { |d| d.provides?(name) }
          if c.nil?
            raise Chef::Exceptions::VerificationNotFound.new "No file verification for #{name} found."
          end
          c
        end

        def initialize(parent_resource, command, opts, &block)
          @command, @command_opts = command, opts
          @block = block
          @parent_resource = parent_resource
        end

        def verify(path, opts = {})
          Chef::Log.debug("Running verification[#{self}] on #{path}")
          if @block
            verify_block(path, opts)
          elsif @command.is_a?(Symbol)
            verify_registered_verification(path, opts)
          elsif @command.is_a?(String)
            verify_command(path, opts)
          end
        end

        # opts is currently unused, but included in the API
        # to support future extensions
        def verify_block(path, opts)
          @block.call(path)
        end

        # We reuse Chef::GuardInterpreter in order to support
        # the same set of options that the not_if/only_if blocks do
        def verify_command(path, opts)
          if @command.include?("%{file}")
            raise ArgumentError, "The %{file} expansion for verify commands has been removed. Please use %{path} instead."
          end
          command = @command % { :path => path }
          interpreter = Chef::GuardInterpreter.for_resource(@parent_resource, command, @command_opts)
          interpreter.evaluate
        end

        def verify_registered_verification(path, opts)
          verification_class = Chef::Resource::File::Verification.lookup(@command)
          v = verification_class.new(@parent_resource, @command, @command_opts, &@block)
          v.verify(path, opts)
        end
      end
    end
  end
end
