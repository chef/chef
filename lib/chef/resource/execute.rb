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

require_relative "../resource"
require_relative "../dist"

class Chef
  class Resource
    class Execute < Chef::Resource
      resource_name :execute
      provides :execute, target_mode: true

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

      property :command, [ String, Array ],
               name_property: true, identity: true,
               description: "An optional property to set the command to be executed if it differs from the resource block's name."

      property :umask, [ String, Integer ],
               description: "The file mode creation mask, or umask."

      property :creates, String,
               description: "Prevent a command from creating a file when that file already exists."

      property :cwd, String,
               description: "The current working directory from which the command will be run."

      property :environment, Hash,
               description: "A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'})."

      property :group, [ String, Integer ],
               description: "The group name or group ID that must be changed before running a command."

      property :live_stream, [ TrueClass, FalseClass ], default: false,
               description: "Send the output of the command run by this execute resource block to the #{Chef::Dist::CLIENT} event stream."

      # default_env defaults to `false` so that the command execution more exactly matches what the user gets on the command line without magic
      property :default_env, [ TrueClass, FalseClass ], desired_state: false, default: false,
               introduced: "14.2",
               description: "When true this enables ENV magic to add path_sanity to the PATH and force the locale to English+UTF-8 for parsing output"

      property :returns, [ Integer, Array ], default: 0,
               description: "The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match."

      property :timeout, [ Integer, Float ],
               description: "The amount of time (in seconds) a command is to wait before timing out."

      property :user, [ String, Integer ],
               description: "The user name of the user identity with which to launch the new process. The user name may optionally be specifed with a domain, i.e. domainuser or user@my.dns.domain.com via Universal Principal Name (UPN)format. It can also be specified without a domain simply as user if the domain is instead specified using the domain property. On Windows only, if this property is specified, the password property must be specified."

      property :domain, String,
               introduced: "12.21",
               description: "Windows only: The domain of the user user specified by the user property. If not specified, the user name and password specified by the user and password properties will be used to resolve that user against the domain in which the system running #{Chef::Dist::PRODUCT} is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the user property."

      property :password, String, sensitive: true,
               introduced: "12.21",
               description: "Windows only: The password of the user specified by the user property. This property is mandatory if user is specified on Windows and may only be specified if user is specified. The sensitive property for this resource will automatically be set to true if password is specified."

      # lazy used to set default value of sensitive to true if password is set
      property :sensitive, [ TrueClass, FalseClass ],
               description: "Ensure that sensitive resource data is not logged by the #{Chef::Dist::CLIENT}.",
               default: lazy { |r| r.password ? true : false }, default_description: "True if the password property is set. False otherwise."

      property :elevated, [ TrueClass, FalseClass ], default: false,
               description: "Determines whether the script will run with elevated permissions to circumvent User Access Control (UAC) interactively blocking the process.\nThis will cause the process to be run under a batch login instead of an interactive login. The user running #{Chef::Dist::CLIENT} needs the “Replace a process level token” and “Adjust Memory Quotas for a process” permissions. The user that is running the command needs the “Log on as a batch job” permission.\nBecause this requires a login, the user and password properties are required.",
               introduced: "13.3"

      alias :env :environment

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

      # post resource creation validation
      #
      # @return [void]
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
