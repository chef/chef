=====================================================
Quick Start
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/quick_start.rst>`__

For the quickest way to get started using Chef:

#. Download the Chef development kit: https://downloads.chef.io/chefdk/.
#. Set your Ruby path:

   .. code-block:: bash

      $ /opt/chefdk/embedded/bin/ruby

#. Generate a cookbook:

   .. code-block:: bash

      $ chef generate app first_cookbook

   where ``first_cookbook`` is an arbitrary cookbook name.

#. Change into the ``first_cookbook`` directory.

#. Update the ``cookbooks/recipes/default.rb`` recipe in the generated cookbook to contain:

   .. code-block:: ruby

      file "#{ENV['HOME']}/test.txt" do
        content 'This file was created by Chef!'
      end

#. Run the chef-client using the ``default.rb`` recipe:

   .. code-block:: bash

      $ chef-client --local-mode --override-runlist first_cookbook

This will create a file named ``test.txt`` at the home path on your machine. Open that file and it will say ``This file was created by Chef!``.

* Delete the file, run the chef-client again, and Chef will put the file back.
* Change the string in the file, run the chef-client again, and Chef will make the string in the file the same as the string in the recipe.
* Change the string in the recipe, run the chef-client again, and Chef will update that string to be the same as the one in the recipe.

There's a lot more that Chef can do, obviously, but that was super easy!

* See https://learn.chef.io/tutorials/ for more detailed setup scenarios.
* Try :doc:`running Chef in the AWS Marketplace </aws_marketplace>`.
* Keep reading  for more information about setting up a workstation, configuring Kitchen to run virtual environments, setting up a more detailed cookbook, resources, and more.
