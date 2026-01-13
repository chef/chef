# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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

module ChefUtils
  #
  # This is glue code to make the helpers work when called as ChefUtils.helper? from inside of chef-client.
  #
  # This also is glue code to make the helpers work when mixed into classes that have node/run_context methods that
  # provide those objects.
  #
  # It should not be assumed that any of this code runs from within chef-client and that the
  # Chef class or run_context, etc exists.
  #
  # This gem may be used by gems like mixlib-shellout which can be consumed by external non-Chef utilities,
  # so including brittle code here which depends on the existence of the chef-client will cause broken
  # behavior downstream.  You must practice defensive coding, and not make assumptions about running within chef-client.
  #
  # Other consumers may mix in the helper classes and then override the methods here and provide their own custom
  # wiring and override what is provided here.  They are marked as private because no downstream user should ever touch
  # them -- they are intended to be subclassable and overridable by Chef developers in other projects.  Chef Software
  # reserves the right to change the implementation details of this class in minor revs which is what "api private" means,
  # so external persons should subclass and override only when necessary (submit PRs and issues upstream if this is a problem).
  #
  module Internal
    extend self

    private

    # This should be set to a Chef::Node instance or to some Hash/Mash-like configuration object with the same keys.  It needs to
    # expose keys like `:os`, `:platform`, `:platform_version` and `:platform_family` at least to be useful.  It will automatically
    # pick up a `node` method when mixed into an object that has that as a method (which is the encouraged "public" API to use
    # for dependency injection rather than overriding the method in this case.
    #
    # @return [Hash] hash-like config object
    #
    # @api private
    def __getnode(skip_global = false)
      # Software developers should feel free to rely on the default wiring here to the node method by implementing the node method in their
      # own class.  For anything more complicated they should completely override the method (overriding the whole method is never wrong and
      # is safer).
      return node if respond_to?(:node) && node

      return run_context&.node if respond_to?(:run_context) && run_context&.node

      unless skip_global
        return Chef.run_context&.node if defined?(Chef) && Chef.respond_to?(:run_context) && Chef.run_context&.node
      end

      nil
    end

    # Just a helper to pull the ENV["PATH"] in a train-independent way
    #
    # @api private
    #
    def __env_path
      if __transport_connection
        __transport_connection.run_command("echo $PATH").stdout.chomp || ""
      else
        ENV["PATH"] || ""
      end
    end

    # This should be set to a Train::Plugins::Transport instance.  You should wire this up to nil for not using a train transport connection.
    #
    # @return [Train::Plugins::Transport]
    #
    # @api private
    #
    def __transport_connection
      # Software consumers MUST override this method with their own implementation.  The default behavior here is subject to change.
      return Chef.run_context.transport_connection if defined?(Chef) && Chef.respond_to?(:run_context) && Chef&.run_context&.transport_connection

      nil
    end

    # This should be set to Chef::Config or to some Hash/Mash-like configuration object with the same keys.  It must not be nil.
    #
    # @return [Hash] hash-like config object
    #
    # @api private
    #
    def __config
      raise NotImplementedError
    end

    # This should be set to Chef::Log or something that duck-types like it.  It must not be nil.
    #
    # @return [Chef::Log] logger-like logging object
    #
    # @api private
    #
    def __log
      raise NotImplementedError
    end

    extend self
  end
end
