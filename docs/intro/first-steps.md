# Quick Start

For the quickest way to get started using Chef:

1. Download the Chef Development Kit from [https://downloads.chef.io/chefdk/](https://downloads.chef.io/chefdk/).
2. Set your Ruby path:

    ```bash
    $ /opt/chefdk/embedded/bin/ruby
    ```

3. Generate a cookbook:

    ```bash
    $ chef generate app first_cookbook
    ```

4. Change into the ``first_cookbook`` directory.

    ```bash
    $ cd first_cookbook
    ```

5. Update the ``cookbooks/recipes/default.rb`` recipe in the generated cookbook to contain:

    ```ruby
    file "#{ENV['HOME']}/test.txt" do
      content 'This file was created by Chef!'
    end
    ```

6. Run the chef-client using the `default.rb` recipe:

    ```bash
    $ chef-client --local-mode --override-runlist first_cookbook
    ```

This will create a file named `test.txt` at the home path on your machine. Open that file and it will say `This file was created by Chef!`.

* Delete the file, run the chef-client again, and Chef will put the file back.
* Change the string in the file, run the chef-client again, and Chef will make the string in the file the same as the string in the recipe.
* Change the string in the recipe, run the chef-client again, and Chef will update that string to be the same as the one in the recipe.

## Next Steps

There's a lot more that Chef can do, obviously, but that was super easy!

* Check out [Learn Chef](https://learn.chef.io/tutorials/) for our more complete tutorials.
* Try [running Chef in the AWS Marketplace](aws_marketplace.rst).
* Keep reading for more information about setting up a workstation, configuring Kitchen to run virtual environments, setting up a more detailed cookbook, resources, and more.
