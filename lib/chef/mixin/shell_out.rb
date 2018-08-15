#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2018, Chef Software Inc.
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

require "mixlib/shellout"
require "chef/mixin/path_sanity"

class Chef
  module Mixin
    module ShellOut
      extend Chef::Mixin::PathSanity

      # PREFERRED APIS:
      #
      # all consumers should now call shell_out!/shell_out.
      #
      # on unix the shell_out API supports the clean_array() kind of syntax (below) so that
      # array args are flat/compact/to_s'd.  on windows, array args aren't supported to its
      # up to the caller to join(" ") on arrays of strings.
      #
      # the shell_out_compacted/shell_out_compacted! APIs are private but are intended for use
      # in rspec tests, and should ideally always be used to make code refactorings that do not
      # change behavior easier:
      #
      # allow(provider).to receive(:shell_out_compacted!).with("foo", "bar", "baz")
      # provider.shell_out!("foo", [ "bar", nil, "baz"])
      # provider.shell_out!(["foo", nil, "bar" ], ["baz"])
      #
      # note that shell_out_compacted also includes adding the magical timeout option to force
      # people to setup expectations on that value explicitly.  it does not include the default_env
      # mangling in order to avoid users having to setup an expectation on anything other than
      # setting `default_env: false` and allow us to make tweak to the default_env without breaking
      # a thousand unit tests.
      #

      def shell_out_compact(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_compact should be replaced by shell_out")
        if options.empty?
          shell_out(*args)
        else
          shell_out(*args, **options)
        end
      end

      def shell_out_compact!(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_compact! should be replaced by shell_out!")
        if options.empty?
          shell_out!(*args)
        else
          shell_out!(*args, **options)
        end
      end

      def shell_out_compact_timeout(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_compact_timeout should be replaced by shell_out")
        if options.empty?
          shell_out(*args, argument_that_will_go_away_in_chef_15_so_do_not_use_it: true)
        else
          shell_out(*args, argument_that_will_go_away_in_chef_15_so_do_not_use_it: true, **options)
        end
      end

      def shell_out_compact_timeout!(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_compact_timeout! should be replaced by shell_out!")
        if options.empty?
          shell_out!(*args, argument_that_will_go_away_in_chef_15_so_do_not_use_it: true)
        else
          shell_out!(*args, argument_that_will_go_away_in_chef_15_so_do_not_use_it: true, **options)
        end
      end

      def shell_out_with_systems_locale(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_with_systems_locale should be replaced by shell_out with the default_env option set to false")
        if options.empty?
          shell_out(*args, default_env: false)
        else
          shell_out(*args, default_env: false, **options)
        end
      end

      def shell_out_with_systems_locale!(*args, **options)
        Chef.deprecated(:shell_out, "shell_out_with_systems_locale! should be replaced by shell_out! with the default_env option set to false")
        if options.empty?
          shell_out!(*args, default_env: false)
        else
          shell_out!(*args, default_env: false, **options)
        end
      end

      def a_to_s(*args)
        Chef.deprecated(:shell_out, "a_to_s is deprecated use shell_out with splat-args")
        args.flatten.reject { |i| i.nil? || i == "" }.map(&:to_s).join(" ")
      end

      def shell_out(*args, **options)
        options = options.dup
        options = Chef::Mixin::ShellOut.maybe_add_timeout(self, options)
        if options.empty?
          shell_out_compacted(*Chef::Mixin::ShellOut.clean_array(*args))
        else
          shell_out_compacted(*Chef::Mixin::ShellOut.clean_array(*args), **options)
        end
      end

      def shell_out!(*args, **options)
        options = options.dup
        options = Chef::Mixin::ShellOut.maybe_add_timeout(self, options)
        if options.empty?
          shell_out_compacted!(*Chef::Mixin::ShellOut.clean_array(*args))
        else
          shell_out_compacted!(*Chef::Mixin::ShellOut.clean_array(*args), **options)
        end
      end

      # helper sugar for resources that support passing timeouts to shell_out
      #
      # module method to not pollute namespaces, but that means we need self injected as an arg
      # @api private
      def self.maybe_add_timeout(obj, options)
        options = options.dup
        force = options.delete(:argument_that_will_go_away_in_chef_15_so_do_not_use_it) # remove in Chef-15
        # historically resources have not properly declared defaults on their timeouts, so a default default of 900s was enforced here
        default_val = 900
        if !force
          return options if options.key?(:timeout) # leave this line in Chef-15, delete the rest of the conditional
        else
          default_val = options[:timeout] if options.key?(:timeout) # delete in Chef-15
        end
        # note that we can't define an empty Chef::Resource::LWRPBase because that breaks descendants tracker, so we'd have to instead require the file here, which would pull in half
        # of chef, so instead convert to using strings.  once descendants tracker is gone, we can just declare the empty classes instead and use `is_a?` against the symbols.
        # (be nice if ruby supported strings in `is_a?` for looser coupling).
        # FIXME: just use `if obj.respond_to?(:new_resource) && obj.new_resource.respond_to?(:timeout) && !options.key?(:timeout)` in Chef 15
        if obj.respond_to?(:new_resource) && ( force || ( obj.class.ancestors.map(&:name).include?("Chef::Provider") && !obj.class.ancestors.map(&:name).include?("Chef::Resource::LWRPBase") && !obj.class.ancestors.map(&:name).include?("Chef::Resource::ActionClass") && obj.new_resource.respond_to?(:timeout) && !options.key?(:timeout) ) )
          options[:timeout] = obj.new_resource.timeout ? obj.new_resource.timeout.to_f : default_val
        end
        options
      end

      # helper function to mangle options when `default_env` is true
      #
      # @api private
      def self.apply_default_env(options)
        options = options.dup
        default_env = options.delete(:default_env)
        default_env = true if default_env.nil?
        if default_env
          env_key = options.key?(:env) ? :env : :environment
          options[env_key] = {
            "LC_ALL" => Chef::Config[:internal_locale],
            "LANGUAGE" => Chef::Config[:internal_locale],
            "LANG" => Chef::Config[:internal_locale],
            env_path => sanitized_path,
          }.update(options[env_key] || {})
        end
        options
      end

      def clean_array(*args)
        Chef.deprecated(:shell_out, "do not call clean_array directly, just use shell_out with splat args or an array")
        Chef::Mixin::ShellOut.clean_array(*args)
      end

      private

      # this SHOULD be used for setting up expectations in rspec, see banner comment at top.
      #
      # the private constraint is meant to avoid code calling this directly, rspec expectations are fine.
      #
      def shell_out_compacted(*args, **options)
        options = Chef::Mixin::ShellOut.apply_default_env(options)
        if options.empty?
          Chef::Mixin::ShellOut.shell_out_command(*args)
        else
          Chef::Mixin::ShellOut.shell_out_command(*args, **options)
        end
      end

      # this SHOULD be used for setting up expectations in rspec, see banner comment at top.
      #
      # the private constraint is meant to avoid code calling this directly, rspec expectations are fine.
      #
      def shell_out_compacted!(*args, **options)
        options = Chef::Mixin::ShellOut.apply_default_env(options)
        cmd = if options.empty?
                Chef::Mixin::ShellOut.shell_out_command(*args)
              else
                Chef::Mixin::ShellOut.shell_out_command(*args, **options)
              end
        cmd.error!
        cmd
      end

      # Helper for subclasses to reject nil out of an array.  It allows
      # using the array form of shell_out (which avoids the need to surround arguments with
      # quote marks to deal with shells).
      #
      # Usage:
      #   shell_out!(*clean_array("useradd", universal_options, useradd_options, new_resource.username))
      #
      # universal_options and useradd_options can be nil, empty array, empty string, strings or arrays
      # and the result makes sense.
      #
      # keeping this separate from shell_out!() makes it a bit easier to write expectations against the
      # shell_out args and be able to omit nils and such in the tests (and to test that the nils are
      # being rejected correctly).
      #
      # @param args [String] variable number of string arguments
      # @return [Array] array of strings with nil and null string rejection

      def self.clean_array(*args)
        args.flatten.compact.map(&:to_s)
      end

      def self.shell_out_command(*args, **options)
        cmd = if options.empty?
                Mixlib::ShellOut.new(*args)
              else
                Mixlib::ShellOut.new(*args, **options)
              end
        cmd.live_stream ||= io_for_live_stream
        cmd.run_command
        cmd
      end

      def self.io_for_live_stream
        if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.debug?
          STDOUT
        else
          nil
        end
      end

      def self.env_path
        if Chef::Platform.windows?
          "Path"
        else
          "PATH"
        end
      end
    end
  end
end

# Break circular dep
require "chef/config"
