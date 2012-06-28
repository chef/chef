require 'chef/knife'
require 'fileutils'

class Chef
  class Knife
    class RepoCreate < Knife

      banner "knife repo create REPO (options)"

      option :repo_path,
        :short       => "-p PATH",
        :long        => "--repository-path PATH",
        :description => "The directory where the repository will be created"

      def run
        self.config = Chef::Config.merge! config

        if @name_args.length < 1
          show_usage
          ui.fatal "You must specify a repository name"
          exit 1
        end

        repo_name = @name_args.first

        path = config[:repo_path] || ''
        path = File.expand_path(path)

        create_repo repo_name, path
      end

      def create_repo(repo_name, path)
        msg "** Creating repo #{repo_name}"

        repo_path = File.join path, repo_name
        FileUtils.mkdir_p repo_path

        create_certificates repo_path
        create_config repo_path
        create_cookbooks repo_path
        create_data_bags repo_path
        create_environments repo_path
        create_roles repo_path

        create_gitignore repo_path
        create_root_readme repo_path
        create_rakefile repo_path
        create_chefignore repo_path

        init_repo repo_path
      end

      private

      def create_dir(repo_path, dir)
        FileUtils.mkdir_p "#{File.join repo_path, dir}"
      end

      def create_file(directory, filename, body)
        unless File.exists?(File.join directory, filename)
          open(File.join(directory, filename), "w") do |file|
            file.puts body
          end
        end
      end

      def init_repo(repo_path)
        begin
          exec "git init #{repo_path}"
        rescue Errno::ENOENT
          # Skip init if git is not found
          msg("** git not found: Could not initialize repository")
        end
      end

      def create_certificates(repo_path)
        create_dir repo_path, "certificates"

        readme_body = <<EOH
Creating SSL certificates is a common task done in web application infrastructures, so a rake task is provided to generate certificates.  These certificates are stored here by the ssl_cert task.  

Configure the values used in the SSL certificate by modifying `config/rake.rb`.

To generate a certificate set for a new monitoring server, for example:

    rake ssl_cert FQDN=monitoring.example.com

Once the certificates are generated, copy them into the cookbook(s) where you want to use them.

    cp certificates/monitoring.example.com.* cookbooks/COOKBOOK/files/default

In the recipe for that cookbook, create a `cookbook_file` resource to configure a resource that puts them in place on the destination server.

    cookbook_file '/etc/apache2/ssl/monitoring.example.com.pem'
      owner 'root'
      group 'root'
      mode 0600
    end
EOH

        create_file "#{repo_path}/certificates", "README.md", readme_body
      end

      def create_config(repo_path)
        create_dir repo_path, "config"

        rake_body = <<EOH
# Configure the Rakefile's tasks.

###
# Company and SSL Details
# Used with the ssl_cert task.
###

# The company name - used for SSL certificates, and in srvious other
places
COMPANY_NAME = "Example Com"

# The Country Name to use for SSL Certificates
SSL_COUNTRY_NAME = "US"

# The State Name to use for SSL Certificates
SSL_STATE_NAME = "Several"

# The Locality Name for SSL - typically, the city
SSL_LOCALITY_NAME = "Locality"

# What department?
SSL_ORGANIZATIONAL_UNIT_NAME = "Operations"

# The SSL contact email address
SSL_EMAIL_ADDRESS = "ops@example.com"

# License for new Cookbooks
# Can be :apachev2 or :none
NEW_COOKBOOK_LICENSE = :apachev2

###
# Useful Extras (which you probably don't need to change)
###

# The top of the repository checkout
TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

# Where to store certificates generated with ssl_cert
CADIR = File.expand_path(File.join(TOPDIR, "certificates"))
EOH

        create_file "#{repo_path}/config", "rake.rb", rake_body 
      end

      def create_cookbooks(repo_path)
        create_dir repo_path, "cookbooks"

        readme_body = <<EOH
This directory contains the cookbooks used to configure systems in your infrastructure with Chef.

Knife needs to be configured to know where the cookbooks are located with the `cookbook_path` setting. If this is not set, then several cookbook operations will fail to work properly.

    cookbook_path ["./cookbooks"]

This setting tells knife to look for the cookbooks directory in the present working directory. This means the knife cookbook subcommands need to be run in the `chef-repo` directory itself. To make sure that the cookbooks can be found elsewhere inside the repository, use an absolute path. This is a Ruby file, so something like the following can be used:

    current_dir = File.dirname(__FILE__)
    cookbook_path ["\#{current_dir}/../cookbooks"]

Which will set `current_dir` to the location of the knife.rb file itself (e.g. `~/chef-repo/.chef/knife.rb`).

Configure knife to use your preferred copyright holder, email contact and license. Add the following lines to `.chef/knife.rb`.

    cookbook_copyright "Example, Com."
    cookbook_email     "cookbooks@example.com"
    cookbook_license   "apachev2"

Supported values for `cookbook_license` are "apachev2", "mit","gplv2","gplv3",  or "none". These settings are used to prefill comments in the default recipe, and the corresponding values in the metadata.rb. You are free to change the the comments in those files.

Create new cookbooks in this directory with Knife.

    knife cookbook create COOKBOOK

This will create all the cookbook directory components. You don't need to use them all, and can delete the ones you don't need. It also creates a README file, metadata.rb and default recipe.

You can also download cookbooks directly from the Opscode Cookbook Site. There are two subcommands to help with this depending on what your preference is.

The first and recommended method is to use a vendor branch if you're using Git. This is automatically handled with Knife.

    knife cookbook site install COOKBOOK

This will:

* Download the cookbook tarball from cookbooks.opscode.com.
* Ensure its on the git master branch.
* Checks for an existing vendor branch, and creates if it doesn't.
* Checks out the vendor branch (chef-vendor-COOKBOOK).
* Removes the existing (old) version.
* Untars the cookbook tarball it downloaded in the first step.
* Adds the cookbook files to the git index and commits.
* Creates a tag for the version downloaded.
* Checks out the master branch again.
* Merges the cookbook into master.
* Repeats the above for all the cookbooks dependencies, downloading them from the community site

The last step will ensure that any local changes or modifications you have made to the cookbook are preserved, so you can keep your changes through upstream updates.

If you're not using Git, use the site download subcommand to download the tarball.

    knife cookbook site download COOKBOOK

This creates the COOKBOOK.tar.gz from in the current directory (e.g., `~/chef-repo`). We recommend following a workflow similar to the above for your version control tool.
EOH

        create_file "#{repo_path}/cookbooks", "README.md", readme_body
      end

      def create_data_bags(repo_path)
        create_dir repo_path, "data_bags"

        readme_body = <<EOH
Data Bags
---------

This directory contains directories of the various data bags you create for your infrastructure. Each subdirectory corresponds to a data bag on the Chef Server, and contains JSON files of the items that go in the bag.

First, create a directory for the data bag.

    mkdir data_bags/BAG

Then create the JSON files for items that will go into that bag.

    $EDITOR data_bags/BAG/ITEM.json

The JSON for the ITEM must contain a key named "id" with a value equal to "ITEM". For example,

    {
      "id": "foo"
    }

Next, create the data bag on the Chef Server.

    knife data bag create BAG

Then upload the items in the data bag's directory to the Chef Server.

    knife data bag from file BAG ITEM.json


Encrypted Data Bags
-------------------

Added in Chef 0.10, encrypted data bags allow you to encrypt the contents of your data bags. The content of attributes will no longer be searchable. To use encrypted data bags, first you must have or create a secret key.

    openssl rand -base64 512 > secret_key

You may use this secret_key to add items to a data bag during a create.

    knife data bag create --secret-file secret_key passwords mysql

You may also use it when adding ITEMs from files,

    knife data bag create passwords
    knife data bag from file passwords data_bags/passwords/mysql.json --secret-file secret_key

The JSON for the ITEM must contain a key named "id" with a value equal to "ITEM" and the contents will be encrypted when uploaded. For example,

    {
      "id": "mysql",
      "password": "abc123"
    }

Without the secret_key, the contents are encrypted.

    knife data bag show passwords mysql
    id:        mysql
    password:  2I0XUUve1TXEojEyeGsjhw==

Use the secret_key to view the contents.

    knife data bag show passwords mysql --secret-file secret_key
    id:        mysql
    password:  abc123
EOH

        create_file "#{repo_path}/data_bags", "README.md", readme_body
      end

      def create_environments(repo_path)
        create_dir repo_path, "environments"

        readme_body = <<EOH
Requires Chef 0.10.0+.

This directory is for Ruby DSL and JSON files for environments. For more information see the Chef wiki page:

http://wiki.opscode.com/display/chef/Environments
EOH
        create_file "#{repo_path}/environments", "README.md", readme_body
      end

      def create_roles(repo_path)
        dir = "roles"
        create_dir repo_path, "roles"

        readme_body = <<EOH
Create roles here, in either the Role Ruby DSL (.rb) or JSON (.json) files. To install roles on the server, use knife.

For example, create `roles/base_example.rb`:

    name "base_example"
    description "Example base role applied to all nodes."
    # List of recipes and roles to apply. Requires Chef 0.8, earlier
    # versions use 'recipes()'.
    #run_list()
    # Attributes applied if the node doesn't have it set already.
    #default_attributes()
    # Attributes applied no matter what the node has set
    already.
    #override_attributes()

Then upload it to the Chef Server:

    knife role from file roles/base_example.rb
EOH
        create_file "#{repo_path}/roles", "README.md", readme_body
      end

      def create_gitignore(repo_path)
        body = ".rake_test_cache"
        create_file repo_path, ".gitignore", body
      end

      def create_root_readme(repo_path)
        body = <<EOH
Overview
========

Every Chef installation needs a Chef Repository. This is the place where cookbooks, roles, config files and other artifacts for managing systems with Chef will live. We strongly recommend storing this repository in a version control system such as Git and treat it like source code.

While we prefer Git, and make this repository available via GitHub, you are welcome to download a tar or zip archive and use your favorite version control system to manage the code.

Repository Directories
======================

This repository contains several directories, and each directory contains a README file that describes what it is for in greater detail, and how to use it for managing your systems with Chef.

* `certificates/` - SSL certificates generated by `rake ssl_cert` live here.
* `config/` - Contains the Rake configuration file, `rake.rb`.
* `cookbooks/` - Cookbooks you download or create.
* `data_bags/` - Store data bags and items in .json in the repository.
* `roles/` - Store roles in .rb or .json in the repository.

Rake Tasks
==========

The repository contains a `Rakefile` that includes tasks that are installed with the Chef libraries. To view the tasks available with in the repository with a brief description, run `rake -T`.

The default task (`default`) is run when executing `rake` with no arguments. It will call the task `test_cookbooks`.

The following tasks are not directly replaced by knife sub-commands.

* `bundle_cookbook[cookbook]` - Creates cookbook tarballs in the `pkgs/` dir.
* `install` - Calls `update`, `roles` and `upload_cookbooks` Rake tasks.
* `ssl_cert` - Create self-signed SSL certificates in `certificates/` dir.
* `update` - Update the repository from source control server, understands git and svn.

The following tasks duplicate functionality from knife and may be removed in a future version of Chef.

* `metadata` - replaced by `knife cookbook metadata -a`.
* `new_cookbook` - replaced by `knife cookbook create`.
* `role[role_name]` - replaced by `knife role from file`.
* `roles` - iterates over the roles and uploads with `knife role from file`.
* `test_cookbooks` - replaced by `knife cookbook test -a`.
* `test_cookbook[cookbook]` - replaced by `knife cookbook test COOKBOOK`.
* `upload_cookbooks` - replaced by `knife cookbook upload -a`.
* `upload_cookbook[cookbook]` - replaced by `knife cookbook upload COOKBOOK`.

Configuration
=============

The repository uses two configuration files.

* config/rake.rb
* .chef/knife.rb

The first, `config/rake.rb` configures the Rakefile in two sections.

* Constants used in the `ssl_cert` task for creating the certificates.
* Constants that set the directory locations used in various tasks.

If you use the `ssl_cert` task, change the values in the `config/rake.rb` file appropriately. These values were also used in the `new_cookbook` task, but that task is replaced by the `knife cookbook create` command which can be configured below.

The second config file, `.chef/knife.rb` is a repository specific configuration file for knife. If you're using the Opscode Platform, you can download one for your organization from the management console. If you're using the Open Source Chef Server, you can generate a new one with `knife configure`. For more information about configuring Knife, see the Knife documentation.

http://help.opscode.com/faqs/chefbasics/knife

Next Steps
==========

Read the README file in each of the subdirectories for more information about what goes in those directories.
EOH
        create_file repo_path, "README.md", body
      end

      def create_rakefile(repo_path)
        body = <<EOH
#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'rubygems'
require 'chef'
require 'json'

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name = "\#{args.cookbook}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/\#{args.cookbook}", "site-cookbooks/\#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path,
    temp_cookbook_dir) if

    File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./\#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end
EOH
        create_file repo_path, "Rakefile", body
      end

      def create_chefignore(repo_path)
        body = <<EOH
# Put files/directories that should be ignored in this file.
# # Lines that start with '# ' are comments.

# emacs
*~

# vim
*.sw[a-z]

# subversion
*/.svn/*
EOH
        create_file repo_path, "chefignore", body
      end
    end
  end
end
