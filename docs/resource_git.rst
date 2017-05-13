=====================================================
git
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_git.rst>`__

.. tag resource_scm_git

Use the **git** resource to manage source control resources that exist in a git repository. git version 1.6.5 (or higher) is required to use all of the functionality in the **git** resource.

.. end_tag

.. note:: .. tag notes_scm_resource_use_with_resource_deploy

          This resource is often used in conjunction with the **deploy** resource.

          .. end_tag

Syntax
=====================================================
A **git** resource block manages source control resources that exist in a git repository:

.. code-block:: ruby

   git "#{Chef::Config[:file_cache_path]}/app_name" do
     repository node[:app_name][:git_repository]
     revision node[:app_name][:git_revision]
     action :sync
   end

The full syntax for all of the properties that are available to the **git** resource is:

.. code-block:: ruby

   git 'name' do
     additional_remotes         Hash
     checkout_branch            String
     depth                      Integer
     destination                String # defaults to 'name' if not specified
     enable_checkout            TrueClass, FalseClass
     enable_submodules          TrueClass, FalseClass
     environment                Hash
     group                      String, Integer
     notifies                   # see description
     provider                   Chef::Provider::Scm::Git
     reference                  String
     remote                     String
     repository                 String
     revision                   String
     ssh_wrapper                String
     subscribes                 # see description
     timeout                    Integer
     user                       String, Integer
     action                     Symbol # defaults to :sync if not specified
   end

where

* ``git`` is the resource
* ``name`` is the name of the resource block and also (when the ``destination`` property is not specified) the location in which the source files will be placed and/or synchronized with the files under source control management
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``additional_remotes``, ``checkout_branch``, ``depth``, ``destination``, ``enable_checkout``, ``enable_submodules``, ``environment``, ``group``, ``provider``, ``reference``, ``remote``, ``repository``, ``revision``, ``ssh_wrapper``, ``timeout``, and ``user`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:checkout``
   Clone or check out the source. When a checkout is available, this provider does nothing.

``:export``
   Export the source, excluding or removing any version control artifacts.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:sync``
   Default. Update the source to the specified version, or get a new clone or checkout. This action causes a hard reset of the index and working tree, discarding any uncommitted changes.

Properties
=====================================================
This resource has the following properties:

``additional_remotes``
   **Ruby Type:** Hash

   An array of additional remotes that are added to the git repository configuration.

``checkout_branch``
   **Ruby Type:** String

   Do a one-time checkout from git **or** use when a branch in the upstream repository is named ``deploy``. To prevent the **git** resource from attempting to check out master from master, set ``enable_checkout`` to ``false`` when using the ``checkout_branch`` property. See ``revision``. Default value: ``deploy``.

``depth``
   **Ruby Type:** Integer

   The number of past revisions to be included in the git shallow clone. The default behavior will do a full clone.

``destination``
   **Ruby Type:** String

   The location path to which the source is to be cloned, checked out, or exported. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``enable_checkout``
   **Ruby Types:** TrueClass, FalseClass

   Check out a repo from master. Set to ``false`` when using the ``checkout_branch`` attribute to prevent the **git** resource from attempting to check out master from master. Default value: ``true``.

``enable_submodules``
   **Ruby Types:** TrueClass, FalseClass

   Perform a sub-module initialization and update. Default value: ``false``.

``environment``
   **Ruby Type:** Hash

   A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

   .. note:: The **git** provider automatically sets the ``ENV['HOME']`` and ``ENV['GIT_SSH']`` environment variables. To override this behavior and provide different values, add ``ENV['HOME']`` and/or ``ENV['GIT_SSH']`` to the ``environment`` Hash.

   New in Chef Client 12.0.

``group``
   **Ruby Types:** String, Integer

   The system group that is responsible for the checked-out code.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``reference``
   **Ruby Type:** String

   The alias for revision.

``remote``
   **Ruby Type:** String

   The remote repository to use when synchronizing an existing clone.

``repository``
   **Ruby Type:** String

   The URI for the git repository.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``revision``
   **Ruby Type:** String

   A branch, tag, or commit to be synchronized with git. This can be symbolic, like ``HEAD`` or it can be a source control management-specific revision identifier. See ``checkout_branch``. Default value: ``HEAD``.

   The value of the ``revision`` attribute may change over time. From one branch to another, to a tag, to a specific SHA for a commit, and then back to a branch. The ``revision`` attribute may even be changed in a way where history gets rewritten.

   Instead of tracking a specific branch or doing a headless checkout, the chef-client maintains its own branch (via the **git** resource) that does not exist in the upstream repository. The chef-client is then free to forcibly check out this branch to any commit without destroying the local history of an existing branch.

   For example, to explicitly track an upstream repository's master branch:

   .. code-block:: ruby

      revision 'master'

   Use the ``git rev-parse`` and ``git ls-remote`` commands to verify that the chef-client is synchronizing commits correctly. (The chef-client always runs ``git ls-remote`` on the upstream repository to verify the commit is made to the correct repository.)

``ssh_wrapper``
   **Ruby Type:** String

   The path to the wrapper script used when running SSH with git. The ``GIT_SSH`` environment variable is set to this.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Type:** Integer

   The amount of time (in seconds) to wait for a command to execute before timing out. When this property is specified using the **deploy** resource, the value of the ``timeout`` property is passed from the **deploy** resource to the **git** resource.

``user``
   **Ruby Types:** String, Integer

   The system user that is responsible for the checked-out code. Default value: the home directory of this user, as indicated by the ``HOME`` environment variable.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Use the git mirror**

.. tag resource_scm_use_git_mirror

.. To use the git mirror:

.. code-block:: ruby

   git '/opt/mysources/couch' do
     repository 'git://git.apache.org/couchdb.git'
     revision 'master'
     action :sync
   end

.. end_tag

**Use different branches**

.. tag resource_scm_use_different_branches

To use different branches, depending on the environment of the node:

.. code-block:: ruby

   if node.chef_environment == 'QA'
      branch_name = 'staging'
   else
      branch_name = 'master'
   end

   git '/home/user/deployment' do
      repository 'git@github.com:gitsite/deployment.git'
      revision branch_name
      action :sync
      user 'user'
      group 'test'
   end

where the ``branch_name`` variable is set to ``staging`` or ``master``, depending on the environment of the node. Once this is determined, the ``branch_name`` variable is used to set the revision for the repository. If the ``git status`` command is used after running the example above, it will return the branch name as ``deploy``, as this is the default value. Run the chef-client in debug mode to verify that the correct branches are being checked out:

.. code-block:: bash

   $ sudo chef-client -l debug

.. end_tag

**Install an application from git using bash**

.. tag resource_scm_use_bash_and_ruby_build

The following example shows how Bash can be used to install a plug-in for rbenv named ``ruby-build``, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ``ruby-build`` is located, and then runs a command.

.. code-block:: ruby

   git "#{Chef::Config[:file_cache_path]}/ruby-build" do
     repository 'git://github.com/sstephenson/ruby-build.git'
     reference 'master'
     action :sync
   end

   bash 'install_ruby_build' do
     cwd '#{Chef::Config[:file_cache_path]}/ruby-build'
     user 'rbenv'
     group 'rbenv'
     code <<-EOH
       ./install.sh
       EOH
     environment 'PREFIX' => '/usr/local'
  end

To read more about ``ruby-build``, see here: https://github.com/sstephenson/ruby-build.

.. end_tag

**Upgrade packages from git**

.. tag resource_scm_upgrade_packages

The following example uses the **git** resource to upgrade packages:

.. code-block:: ruby

   # the following code sample comes from the ``source`` recipe
   # in the ``libvpx-cookbook`` cookbook:
   # https://github.com/enmasse-entertainment/libvpx-cookbook

   git "#{Chef::Config[:file_cache_path]}/libvpx" do
     repository node[:libvpx][:git_repository]
     revision node[:libvpx][:git_revision]
     action :sync
     notifies :run, 'bash[compile_libvpx]', :immediately
   end

.. end_tag

**Pass in environment variables**

.. tag resource_scm_git_environment_variables

.. To pass in environment variables:

.. code-block:: ruby

   git '/opt/mysources/couch' do
     repository 'git://git.apache.org/couchdb.git'
     revision 'master'
     environment  { 'VAR' => 'whatever' }
     action :sync
   end

.. end_tag
