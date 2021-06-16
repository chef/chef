#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class Execute < Chef::Resource
      unified_mode true

      provides :execute, target_mode: true

      description "Use the **execute** resource to execute a single command. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence. Note: Use the **script** resource to execute a script using a specific interpreter (Ruby, Python, Perl, csh, or Bash)."

      examples <<~EXAMPLES
        **Run a command upon notification**:

        ```ruby
        execute 'slapadd' do
          command 'slapadd < /tmp/something.ldif'
          creates '/var/lib/slapd/uid.bdb'

          action :nothing
        end

        template '/tmp/something.ldif' do
          source 'something.ldif'

          notifies :run, 'execute[slapadd]', :immediately
        end
        ```

        **Run a touch file only once while running a command**:

        ```ruby
        execute 'upgrade script' do
          command 'php upgrade-application.php && touch /var/application/.upgraded'

          creates '/var/application/.upgraded'
          action :run
        end
        ```

        **Run a command which requires an environment variable**:

        ```ruby
        execute 'slapadd' do
          command 'slapadd < /tmp/something.ldif'
          creates '/var/lib/slapd/uid.bdb'

          action :run
          environment ({'HOME' => '/home/my_home'})
        end
        ```

        **Delete a repository using yum to scrub the cache**:

        ```ruby
        # the following code sample thanks to gaffneyc @ https://gist.github.com/918711
        execute 'clean-yum-cache' do
          command 'yum clean all'
          action :nothing
        end

        file '/etc/yum.repos.d/bad.repo' do
          action :delete
          notifies :run, 'execute[clean-yum-cache]', :immediately
        end
        ```

        **Prevent restart and reconfigure if configuration is broken**:

        Use the `:nothing` action (common to all resources) to prevent the test from
        starting automatically, and then use the `subscribes` notification to run a
        configuration test when a change to the template is detected.

        ```ruby
        execute 'test-nagios-config' do
          command 'nagios3 --verify-config'
          action :nothing
          subscribes :run, 'template[/etc/nagios3/configures-nagios.conf]', :immediately
        end
        ```

        **Notify in a specific order**:

        To notify multiple resources, and then have these resources run in a certain
        order, do something like the following.

        ```ruby
        execute 'foo' do
          command '...'
          notifies :create, 'template[baz]', :immediately
          notifies :install, 'package[bar]', :immediately
          notifies :run, 'execute[final]', :immediately
        end

        template 'baz' do
          #...
          notifies :run, 'execute[restart_baz]', :immediately
        end

        package 'bar'
          execute 'restart_baz'
          execute 'final' do
          command '...'
        end
        ```

        where the sequencing will be in the same order as the resources are listed in
        the recipe: `execute 'foo'`, `template 'baz'`, `execute [restart_baz]`,
        `package 'bar'`, and `execute 'final'`.

        **Execute a command using a template**:

        The following example shows how to set up IPv4 packet forwarding using the
        **execute** resource to run a command named `forward_ipv4` that uses a template
        defined by the **template** resource.

        ```ruby
        execute 'forward_ipv4' do
          command 'echo > /proc/.../ipv4/ip_forward'
          action :nothing
        end

        template '/etc/file_name.conf' do
          source 'routing/file_name.conf.erb'

         notifies :run, 'execute[forward_ipv4]', :delayed
        end
        ```

        where the `command` property for the **execute** resource contains the command
        that is to be run and the `source` property for the **template** resource
        specifies which template to use. The `notifies` property for the **template**
        specifies that the `execute[forward_ipv4]` (which is defined by the **execute**
        resource) should be queued up and run at the end of a Chef Infra Client run.

        **Add a rule to an IP table**:

        The following example shows how to add a rule named `test_rule` to an IP table
        using the **execute** resource to run a command using a template that is defined
        by the **template** resource:

        ```ruby
        execute 'test_rule' do
          command "command_to_run
            --option value
            --option value
            --source \#{node[:name_of_node][:ipsec][:local][:subnet]}
            -j test_rule"

          action :nothing
        end

        template '/etc/file_name.local' do
          source 'routing/file_name.local.erb'
          notifies :run, 'execute[test_rule]', :delayed
        end
        ```

        where the `command` property for the **execute** resource contains the command
        that is to be run and the `source` property for the **template** resource
        specifies which template to use. The `notifies` property for the **template**
        specifies that the `execute[test_rule]` (which is defined by the **execute**
        resource) should be queued up and run at the end of a Chef Infra Client run.

        **Stop a service, do stuff, and then restart it**:

        The following example shows how to use the **execute**, **service**, and
        **mount** resources together to ensure that a node running on Amazon EC2 is
        running MySQL. This example does the following:

        - Checks to see if the Amazon EC2 node has MySQL
        - If the node has MySQL, stops MySQL
        - Installs MySQL
        - Mounts the node
        - Restarts MySQL

        ```ruby
        # the following code sample comes from the ``server_ec2``
        # recipe in the following cookbook:
        # https://github.com/chef-cookbooks/mysql

        if (node.attribute?('ec2') && !FileTest.directory?(node['mysql']['ec2_path']))
          service 'mysql' do
            action :stop
          end

          execute 'install-mysql' do
            command "mv \#{node['mysql']['data_dir']} \#{node['mysql']['ec2_path']}"
            not_if { ::File.directory?(node['mysql']['ec2_path']) }
          end

          [node['mysql']['ec2_path'], node['mysql']['data_dir']].each do |dir|
            directory dir do
              owner 'mysql'
              group 'mysql'
            end
          end

          mount node['mysql']['data_dir'] do
            device node['mysql']['ec2_path']
            fstype 'none'
            options 'bind,rw'
            action [:mount, :enable]
          end

          service 'mysql' do
            action :start
          end
        end
        ```

        where

        - the two **service** resources are used to stop, and then restart the MySQL service
        - the **execute** resource is used to install MySQL
        - the **mount** resource is used to mount the node and enable MySQL

        **Use the platform_family? method**:

        The following is an example of using the `platform_family?` method in the Recipe
        DSL to create a variable that can be used with other resources in the same
        recipe. In this example, `platform_family?` is being used to ensure that a
        specific binary is used for a specific platform before using the **remote_file**
        resource to download a file from a remote location, and then using the
        **execute** resource to install that file by running a command.

        ```ruby
        if platform_family?('rhel')
          pip_binary = '/usr/bin/pip'
        else
          pip_binary = '/usr/local/bin/pip'
        end

        remote_file "\#{Chef::Config[:file_cache_path]}/distribute_setup.py" do
          source 'http://python-distribute.org/distribute_setup.py'
          mode '0755'
          not_if { ::File.exist?(pip_binary) }
        end

        execute 'install-pip' do
          cwd Chef::Config[:file_cache_path]
          command <<~EOF
            # command for installing Python goes here
          EOF
          not_if { ::File.exist?(pip_binary) }
        end
        ```

        where a command for installing Python might look something like:

        ```ruby
        \#{node['python']['binary']} distribute_setup.py \#{::File.dirname(pip_binary)}/easy_install pip
        ```

        **Control a service using the execute resource**:

        <div class="admonition-warning">
          <p class="admonition-warning-title">Warning</p>
          <div class="admonition-warning-text">
            This is an example of something that should NOT be done. Use the **service**
            resource to control a service, not the **execute** resource.
          </div>
        </div>

        Do something like this:

        ```ruby
        service 'tomcat' do
          action :start
        end
        ```

        and NOT something like this:

        ```ruby
        execute 'start-tomcat' do
          command '/etc/init.d/tomcat start'
          action :run
        end
        ```

        There is no reason to use the **execute** resource to control a service because
        the **service** resource exposes the `start_command` property directly, which
        gives a recipe full control over the command issued in a much cleaner, more
        direct manner.

        **Use the search Infra Language helper to find users**:

        The following example shows how to use the `search` method in the Chef Infra Language to
        search for users:

        ```ruby
        #  the following code sample comes from the openvpn cookbook:

        search("users", "*:*") do |u|
          execute "generate-openvpn-\#{u['id']}" do
            command "./pkitool \#{u['id']}"
            cwd '/etc/openvpn/easy-rsa'
          end

          %w{ conf ovpn }.each do |ext|
            template "\#{node['openvpn']['key_dir']}/\#{u['id']}.\#{ext}" do
              source 'client.conf.erb'
              variables :username => u['id']
            end
          end
        end
        ```

        where

        - the search data will be used to create **execute** resources
        - the **template** resource tells Chef Infra Client which template to use

        **Enable remote login for macOS**:

        ```ruby
        execute 'enable ssh' do
          command '/usr/sbin/systemsetup -setremotelogin on'
          not_if '/usr/sbin/systemsetup -getremotelogin | /usr/bin/grep On'
          action :run
        end
        ```

        **Execute code immediately, based on the template resource**:

        By default, notifications are `:delayed`, that is they are queued up as they are
        triggered, and then executed at the very end of a Chef Infra Client run. To run
        kan action immediately, use `:immediately`:

        ```ruby
        template '/etc/nagios3/configures-nagios.conf' do
          # other parameters
          notifies :run, 'execute[test-nagios-config]', :immediately
        end
        ```

        and then Chef Infra Client would immediately run the following:

        ```ruby
        execute 'test-nagios-config' do
          command 'nagios3 --verify-config'
          action :nothing
        end
        ```

        **Sourcing a file**:

        The **execute** resource cannot be used to source a file (e.g. `command 'source
        filename'`). The following example will fail because `source` is not an
        executable:

        ```ruby
        execute 'foo' do
          command 'source /tmp/foo.sh'
        end
        ```


        Instead, use the **script** resource or one of the **script**-based resources
        (**bash**, **csh**, **perl**, **python**, or **ruby**). For example:

        ```ruby
        bash 'foo' do
          code 'source /tmp/foo.sh'
        end
        ```

        **Run a Knife command**:

        ```ruby
        execute 'create_user' do
          command <<~EOM
            knife user create \#{user}
              --admin
              --password password
              --disable-editing
              --file /home/vagrant/.chef/user.pem
              --config /tmp/knife-admin.rb
            EOM
        end
        ```

        **Run install command into virtual environment**:

        The following example shows how to install a lightweight JavaScript framework
        into Vagrant:

        ```ruby
        execute "install q and zombiejs" do
          cwd "/home/vagrant"
          user "vagrant"
          environment ({'HOME' => '/home/vagrant', 'USER' => 'vagrant'})
          command "npm install -g q zombie should mocha coffee-script"
          action :run
        end
        ```

        **Run a command as a named user**:

        The following example shows how to run `bundle install` from a Chef Infra Client
        run as a specific user. This will put the gem into the path of the user
        (`vagrant`) instead of the root user (under which the Chef Infra Client runs):

        ```ruby
        execute '/opt/chefdk/embedded/bin/bundle install' do
          cwd node['chef_workstation']['bundler_path']
          user node['chef_workstation']['user']

          environment ({
            'HOME' => "/home/\#{node['chef_workstation']['user']}",
            'USER' => node['chef_workstation']['user']
          })
          not_if 'bundle check'
        end
        ```

        **Run a command as an alternate user**:

        *Note*: When Chef is running as a service, this feature requires that the user
        that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka
        'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and
        NetworkService have this right when running as a service. This is necessary
        even if the user is an Administrator.

        This right can be added and checked in a recipe using this example:

        ```ruby
        # Add 'SeAssignPrimaryTokenPrivilege' for the user
        Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

        # Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
        Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')
        ```

        The following example shows how to run `mkdir test_dir` from a Chef Infra Client
        run as an alternate user.

        ```ruby
        # Passing only username and password
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "username"
          password "password"
        end

        # Passing username and domain
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          domain "domain-name"
          user "user"
          password "password"
        end

        # Passing username = 'domain-name\\username'. No domain is passed
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "domain-name\\username"
          password "password"
        end

        # Passing username = 'username@domain-name'.  No domain is passed
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "username@domain-name"
          password "password"
        end
        ```

        **Run a command with an external input file**:

        execute 'md5sum' do
          input File.read(__FILE__)
        end
      EXAMPLES

      # The ResourceGuardInterpreter wraps a resource's guards in another resource.  That inner resource
      # needs to behave differently during (for example) why_run mode, so we flag it here. For why_run mode
      # we still want to execute the guard resource even if we are not executing the wrapping resource.
      # Only execute resources (and subclasses) can be guard interpreters.
      attr_accessor :is_guard_interpreter

      default_action :run

      def initialize(name, run_context = nil)
        super
        @command = name
        @default_guard_interpreter = :execute
        @is_guard_interpreter = false
      end

      property :command, [ String, Array ],
        name_property: true,
        description: "An optional property to set the command to be executed if it differs from the resource block's name. Note: Use the **execute** resource to run a single command. Use multiple **execute** resource blocks to run multiple commands."

      property :umask, [ String, Integer ],
        description: "The file mode creation mask, or umask."

      property :creates, String,
        description: "Prevent a command from creating a file when that file already exists."

      property :cwd, String,
        description: "The current working directory from which the command will be run."

      property :environment, Hash,
        description: "A Hash of environment variables in the form of `({'ENV_VARIABLE' => 'VALUE'})`. **Note**: These variables must exist for a command to be run successfully."

      property :group, [ String, Integer ],
        description: "The group name or group ID that must be changed before running a command."

      property :live_stream, [ TrueClass, FalseClass ], default: false,
        description: "Send the output of the command run by this execute resource block to the #{ChefUtils::Dist::Infra::PRODUCT} event stream."

      # default_env defaults to `false` so that the command execution more exactly matches what the user gets on the command line without magic
      property :default_env, [ TrueClass, FalseClass ], desired_state: false, default: false,
        introduced: "14.2",
        description: "When true this enables ENV magic to add path_sanity to the PATH and force the locale to English+UTF-8 for parsing output"

      property :returns, [ Integer, Array ], default: 0,
        description: "The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match."

      property :timeout, [ Integer, String, Float ],
        default: 3600,
        description: "The amount of time (in seconds) a command is to wait before timing out.",
        desired_state: false

      property :user, [ String, Integer ],
        description: "The user name of the user identity with which to launch the new process. The user name may optionally be specified with a domain, i.e. `domainuser` or `user@my.dns.domain.com` via Universal Principal Name (UPN)format. It can also be specified without a domain simply as user if the domain is instead specified using the domain property. On Windows only, if this property is specified, the password property must be specified."

      property :domain, String,
        introduced: "12.21",
        description: "Windows only: The domain of the user user specified by the user property. If not specified, the username and password specified by the `user` and `password` properties will be used to resolve that user against the domain in which the system running #{ChefUtils::Dist::Infra::PRODUCT} is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the user property."

      property :password, String, sensitive: true,
        introduced: "12.21",
        description: "Windows only: The password of the user specified by the user property. This property is mandatory if user is specified on Windows and may only be specified if user is specified. The sensitive property for this resource will automatically be set to true if password is specified."

      # lazy used to set default value of sensitive to true if password is set
      property :sensitive, [ TrueClass, FalseClass ],
        description: "Ensure that sensitive resource data is not logged by the #{ChefUtils::Dist::Infra::PRODUCT}.",
        default: lazy { password ? true : false }, default_description: "True if the password property is set. False otherwise."

      property :elevated, [ TrueClass, FalseClass ], default: false,
        description: "Determines whether the script will run with elevated permissions to circumvent User Access Control (UAC) from interactively blocking the process.\nThis will cause the process to be run under a batch login instead of an interactive login. The user running #{ChefUtils::Dist::Infra::CLIENT} needs the 'Replace a process level token' and 'Adjust Memory Quotas for a process' permissions. The user that is running the command needs the 'Log on as a batch job' permission.\nBecause this requires a login, the user and password properties are required.",
        introduced: "13.3"

      property :input, [String],
        introduced: "16.2",
        description: "An optional property to set the input sent to the command as STDIN."

      property :login, [ TrueClass, FalseClass ], default: false,
        introduced: "17.0",
        description: "Use a login shell to run the commands instead of inheriting the existing execution environment."

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

        ancestor_attributes.concat(@class_inherited_attributes || []).uniq
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
        if windows?
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
        if specified_user.is_a?(String) && ((specified_user.include? "\\") || (specified_user.include? "@")) && specified_domain
          raise ArgumentError, "The domain is provided twice. Username: `#{specified_user}`, Domain: `#{specified_domain}`. Please specify domain only once."
        end

        if specified_user.is_a?(String) && specified_domain.nil?
          # Splitting username of format: Domain\Username
          domain_and_user = user.split("\\")

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
        :domain,
        :environment,
        :group,
        :password,
        :user,
        :umask,
        :login
      )

    end
  end
end
