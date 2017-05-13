=====================================================
About Cookbook Versions
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/cookbook_versions.rst>`__

.. tag cookbooks_version

A cookbook version represents a set of functionality that is different from the cookbook on which it is based. A version may exist for many reasons, such as ensuring the correct use of a third-party component, updating a bug fix, or adding an improvement. A cookbook version is defined using syntax and operators, may be associated with environments, cookbook metadata, and/or run-lists, and may be frozen (to prevent unwanted updates from being made).

A cookbook version is maintained just like a cookbook, with regard to source control, uploading it to the Chef server, and how the chef-client applies that cookbook when configuring nodes.

.. end_tag

Syntax
=====================================================
A cookbook version always takes the form x.y.z, where x, y, and z are decimal numbers that are used to represent major (x), minor (y), and patch (z) versions. A two-part version (x.y) is also allowed. Alphanumeric version numbers (1.2.a3) and version numbers with more than three parts (1.2.3.4) are not allowed.

Constraints
=====================================================
A version constraint is a string that combines the cookbook version syntax with an operator, in the following format:

.. code-block:: ruby

   operator cookbook_version_syntax

.. note:: Single digit cookbook versions are not allowed. Cookbook versions must specify at least the major and minor version. For example, use ``1.0`` or ``1.0.1``; do not use ``1``.

.. tag cookbooks_version_constraints_operators

The following operators may be used:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Operator
     - Description
   * - ``=``
     - equal to
   * - ``>``
     - greater than
   * - ``<``
     - less than
   * - ``>=``
     - greater than or equal to; also known as "optimistically greater than", or "optimistic"
   * - ``<=``
     - less than or equal to
   * - ``~>``
     - approximately greater than; also known as "pessimistically greater than", or "pessimistic"

.. end_tag

For example, a version constraint for "equals version 1.0.7" is expressed like this:

.. code-block:: ruby

   = 1.0.7

A version constraint for "greater than version 1.0.2" is expressed like this:

.. code-block:: ruby

   > 1.0.2

An optimistic version constraint is one that looks for versions greater than or equal to the specified version. For example:

.. code-block:: ruby

   >= 2.6.5

will match cookbooks greater than or equal to 2.6.5, such as 2.6.5, 2.6.7 or 3.1.1.

A pessimistic version constraint is one that will find the upper limit version number within the range specified by the minor version number or patch version number. For example, a pessimistic version constraint for minor version numbers:

.. code-block:: ruby

   ~> 2.6

will match cookbooks that are greater than or equal to version 2.6, but less than version 3.0.

Or, a pessimistic version constraint for patch version numbers:

.. code-block:: ruby

   ~> 2.6.5

will match cookbooks that are greater than or equal to version 2.6.5, but less than version 2.7.0.

Or, a pessimistic version constraint that matches cookbooks less than a version number:

.. code-block:: ruby

   < 2.3.4

or will match cookbooks less than or equal to a specific version number:

.. code-block:: ruby

   <= 2.6.5

Metadata
=====================================================
.. tag cookbooks_metadata

Every cookbook requires a small amount of metadata. A file named metadata.rb is located at the top of every cookbook directory structure. The contents of the metadata.rb file provides hints to the Chef server to help ensure that cookbooks are deployed to each node correctly.

.. end_tag

Versions and version constraints can be specified in a cookbook's metadata.rb file by using the following functions. Each function accepts a name and an optional version constraint; if a version constraint is not provided, ``>= 0.0.0`` is used as the default.

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Function
     - Description
   * - ``conflicts``
     - A cookbook conflicts with another cookbook or cookbook version. Use a version constraint to define constraints for cookbook versions: ``<`` (less than), ``<=`` (less than or equal to), ``=`` (equal to), ``>=`` (greater than or equal to), ``~>`` (approximately greater than), or ``>`` (greater than). This field requires that a cookbook with a matching name and version does not exist on the Chef server. When the match exists, the Chef server ensures that any conflicted cookbooks are not included with the set of cookbooks that are sent to the node when the chef-client runs. For example:

       .. code-block:: ruby

          conflicts 'apache2', '< 3.0'

       or:

       .. code-block:: ruby

          conflicts 'daemon-tools'

   * - ``depends``
     - Show that a cookbook has a dependency on another cookbook. Use a version constraint to define dependencies for cookbook versions: ``<`` (less than), ``<=`` (less than or equal to), ``=`` (equal to), ``>=`` (greater than or equal to; also known as "optimistically greater than", or "optimistic"), ``~>`` (approximately greater than; also known as "pessimistically greater than", or "pessimistic"), or ``>`` (greater than). This field requires that a cookbook with a matching name and version exists on the Chef server. When the match exists, the Chef server includes the dependency as part of the set of cookbooks that are sent to the node when the chef-client runs. It is very important that the ``depends`` field contain accurate data. If a dependency statement is inaccurate, the chef-client may not be able to complete the configuration of the system. For example:

       .. code-block:: ruby

          depends 'opscode-base'

       or:

       .. code-block:: ruby

          depends 'opscode-github', '> 1.0.0'

       or:

       .. code-block:: ruby

          depends 'runit', '~> 1.2.3'

   * - ``provides``
     - Add a recipe, definition, or resource that is provided by this cookbook, should the auto-populated list be insufficient. New in Chef Client 12.0.

   * - ``recommends``
     - Add a dependency on another cookbook that is recommended, but not required. A cookbook will still work even if recommended dependencies are not available.
   * - ``replaces``
     - Whether this cookbook should replace another (and can be used in-place of that cookbook).
   * - ``suggests``
     - Add a dependency on another cookbook that is suggested, but not required. This field is weaker than ``recommends``; a cookbook will still work even when suggested dependencies are not available.
   * - ``supports``
     - Show that a cookbook has a supported platform. Use a version constraint to define dependencies for platform versions: ``<`` (less than), ``<=`` (less than or equal to), ``=`` (equal to), ``>=`` (greater than or equal to), ``~>`` (approximately greater than), or ``>`` (greater than). To specify more than one platform, use more than one ``supports`` field, once for each platform.

Environments
=====================================================
An environment can use version constraints to specify a list of allowed cookbook versions by specifying the cookbook's name, along with the version constraint. For example:

.. code-block:: ruby

   cookbook 'apache2', '~> 1.2.3'

Or:

.. code-block:: ruby

   cookbook 'runit', '= 4.2.0'

If a cookbook is not explicitly given a version constraint the environment will assume the cookbook has no version constraint and will use any version of that cookbook with any node in the environment.

Freeze Versions
=====================================================
A cookbook version can be frozen, which will prevent updates from being made to that version of a cookbook. (A user can always upload a new version of a cookbook.) Using cookbook versions that are frozen within environments is a reliable way to keep a production environment safe from accidental updates while testing changes that are made to a development infrastructure.

For example, to freeze a cookbook version using knife, enter:

.. code-block:: bash

   $ knife cookbook upload redis --freeze

To return:

.. code-block:: bash

   Uploading redis...
   Upload completed

Once a cookbook version is frozen, only by using the ``--force`` option can an update be made. For example:

.. code-block:: bash

   $ knife cookbook upload redis --force

Without the ``--force`` option specified, an error will be returned similar to:

.. code-block:: none

   Version 0.0.0 of cookbook redis is frozen. Use --force to override

Version Source Control
=====================================================
There are two strategies to consider when using version control as part of the cookbook management process:

* Use maximum version control when it is important to keep every bit of data within version control
* Use branch tracking when cookbooks are being managed in separate environments using git branches and the versioning policy information is already stored in a cookbook's metadata.

Branch Tracking
-----------------------------------------------------
Using a branch tracking strategy requires that a branch for each environment exists in the source control and that each cookbook's versioning policy is tracked at the branch level. This approach is relatively simple and lightweight: for development environments that track the latest cookbooks, just bump the version before a cookbook is uploaded for testing. For any cookbooks that require higher levels of version control, knife allows cookbooks to be uploaded to specific environments and for cookbooks to be frozen (which prevents others from being able to make changes to that cookbook).

The typical workflow with a branch tracking version control strategy includes:

#. Bumping the version number as appropriate.
#. Making changes to a cookbook.
#. Uploading and testing a cookbook.
#. Moving a tested cookbook to production.

For example, to bump a version number, first make changes to the cookbook, and then upload and test it. Repeat this process as required, and then upload it using a knife command similar to:

.. code-block:: bash

   $ knife cookbook upload my-app

When the cookbook is finished, move those changes to the production environment and use the ``--freeze`` option to prevent others from making further changes:

.. code-block:: bash

   $ knife cookbook upload  my-app -E production --freeze

Maximum Versions
-----------------------------------------------------
Using a maximum version control strategy is required when everything needs to be tracked in source control. This approach is very similar to a branch tracking strategy while the cookbook is in development and being tested, but is more complicated and time-consuming (and requires file-level editing for environment data) in order to get the cookbook deployed to a production environment.

The typical workflow with a maximum version control strategy includes:

#. Bumping the version number as appropriate.
#. Making changes to a cookbook.
#. Uploading and testing a cookbook.
#. Moving a tested cookbook to production.

For example, to bump a version number, first make changes to the cookbook, and then upload and test it. Repeat this process as required, and then upload it using a knife command similar to:

.. code-block:: bash

   $ knife cookbook upload my-app

When the cookbook is finished, move those changes to the production environment and use the ``--freeze`` option to prevent others from making further changes:

.. code-block:: bash

   $ knife cookbook upload  my-app -E production --freeze

Then modify the environment so that it prefers the newly uploaded version:

.. code-block:: bash

  (vim|emacs|mate|ed) YOUR_REPO/environments/production.rb

Upload the updated environment:

.. code-block:: bash

   $ knife environment from file production.rb

And then deploy the new cookbook version.
