#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

require "chef/resource"

class Chef
  class Resource
    class Execute < Chef::Resource
      resource_name :execute
      provides :execute

      identity_attr :command

      description "Use the execute resource to execute a single command. Commands that"\
                  " are executed with this resource are (by their nature) not idempotent,"\
                  " as they are typically unique to the environment in which they are run."\
                  " Use not_if and only_if to guard this resource for idempotence."

      # The ResourceGuardInterpreter wraps a resource's guards in another resource.  That inner resource
      # needs to behave differently during (for example) why_run mode, so we flag it here. For why_run mode
      # we still want to execute the guard resource even if we are not executing the wrapping resource.
      # Only execute resources (and subclasses) can be guard interpreters.
      attr_accessor :is_guard_interpreter

      default_action :run

      def initialize(name, run_context = nil)
        super
        @command = name
        @backup = 5
        @default_guard_interpreter = :execute
        @is_guard_interpreter = false
      end

      def command(arg = nil)
        set_or_return(
          :command,
          arg,
          :kind_of => [ String, Array ]
        )
      end
      property :umask, [ String, Integer ]
      property :creates, String
      property :cwd, String
      property :environment, Hash

      alias :env :environment

      property :group, [ String, Integer ]
      property :live_stream, [ TrueClass, FalseClass ], default: false
      # internal defaults to `false` so that the command execution more exactly matches what the user gets on the command line without magic
      property :internal, [ TrueClass, FalseClass ], desired_state: false, default: false,
        description: "When true this enables ENV magic to add path_sanity to the PATH and force the locale to English+UTF-8 for parsing output"
      property :returns, [ Integer, Array ], default: 0
      property :timeout, [ Integer, Float ]
      property :user, [ String, Integer ]
      property :domain, String
      property :password, String, sensitive: true

      # lazy used to set default value of sensitive to true if password is set
      property :sensitive, [ TrueClass, FalseClass ], default: lazy { |r| r.password ? true : false }

      property :elevated, [ TrueClass, FalseClass ], default: false

      def self.set_guard_inherited_attributes(*inherited_attributes)
        @class_inherited_attributes = inherited_attributes
      end

      def self.guard_inherited_attributes(*inherited_attributes)
        # Similar to patterns elsewhere, return attributes from this
        # class and superclasses as a form of inheritance
        ancestor_attributes = []

        if superclass.respond_to?(:guard_inherited_attributes)
          ancestor_attributes = superclass.guard_inherited_attributes
        end

        ancestor_attributes.concat(@class_inherited_attributes ? @class_inherited_attributes : []).uniq
      end

      def after_created
        validate_identity_platform(user, password, domain, elevated)
        identity = qualify_user(user, password, domain)
        domain(identity[:domain])
        user(identity[:user])
      end

      def validate_identity_platform(specified_user, password = nil, specified_domain = nil, elevated = false)
        if node[:platform_family] == "windows"
          if specified_user && password.nil?
            raise ArgumentError, "A value for `password` must be specified when a value for `user` is specified on the Windows platform"
          end

          if elevated && !specified_user && !password
            raise ArgumentError, "`elevated` option should be passed only with `username` and `password`."
          end
        else
          if password || specified_domain
            raise Exceptions::UnsupportedPlatform, "Values for `domain` and `password` are only supported on the Windows platform"
          end

          if elevated
            raise Exceptions::UnsupportedPlatform, "Value for `elevated` is only supported on the Windows platform"
          end
        end
      end

      def qualify_user(specified_user, password = nil, specified_domain = nil)
        domain = specified_domain
        user = specified_user

        if specified_user.nil? && ! specified_domain.nil?
          raise ArgumentError, "The domain `#{specified_domain}` was specified, but no user name was given"
        end

        # if domain is provided in both username and domain
        if specified_user && ((specified_user.include? '\\') || (specified_user.include? "@")) && specified_domain
          raise ArgumentError, "The domain is provided twice. Username: `#{specified_user}`, Domain: `#{specified_domain}`. Please specify domain only once."
        end

        if ! specified_user.nil? && specified_domain.nil?
          # Splitting username of format: Domain\Username
          domain_and_user = user.split('\\')

          if domain_and_user.length == 2
            domain = domain_and_user[0]
            user = domain_and_user[1]
          elsif domain_and_user.length == 1
            # Splitting username of format: Username@Domain
            domain_and_user = user.split("@")
            if domain_and_user.length == 2
              domain = domain_and_user[1]
              user = domain_and_user[0]
            elsif domain_and_user.length != 1
              raise ArgumentError, "The specified user name `#{user}` is not a syntactically valid user name"
            end
          end
        end

        if ( password || domain ) && user.nil?
          raise ArgumentError, "A value for `password` or `domain` was specified without specification of a value for `user`"
        end

        { domain: domain, user: user }
      end

      set_guard_inherited_attributes(
        :cwd,
        :environment,
        :group,
        :user,
        :umask
      )

    end
  end
end
