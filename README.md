# Chef Omnibus project

This project creates full-stack platform-specific packages for `chef`!

__PLEASE NOTE__ - The `chef-server` Omnibus project has been moved to:
https://github.com/opscode/omnibus-chef-server

## Installation

We'll assume you have Ruby 1.9+ and Bundler installed. First ensure all
required gems are installed and ready to use:

```shell
$ bundle install --binstubs
```

## Usage

### Build

You create a platform-specific package using the `build project` command:

```shell
$ bin/omnibus build chef
```

The platform/architecture type of the package created will match the platform
where the `build project` command is invoked. So running this command on say a
MacBook Pro will generate a Mac OS X specific package. After the build
completes packages will be available in `pkg/`.

### Clean

You can clean up all temporary files generated during the build process with
the `clean` command:

```shell
$ bin/omnibus clean
```

Adding the `--purge` purge option removes __ALL__ files generated during the
build including the project install directory (`/opt/opscode`) and
the package cache directory (`/var/cache/omnibus/pkg`):

```shell
$ bin/omnibus clean --purge
```

### Cache

Lists source packages that are required but not yet cached:

```shell
$ bin/omnibus cache missing
```

Populate the S3 Cache:

```shell
$ bin/omnibus cache populate
```

### Help

Full help for the Omnibus command line interface can be accessed with the
`help` command:

```shell
$ bin/omnibus help
```

## Specifying a Chef version

By default, the package you build will be based on master branch HEAD of the
[opscode/chef](https://github.com/opscode/chef) git repository. You can build
packages for a specific version of Chef by overriding the version of chef in
Chef project definition.

```ruby
# config/projects/chef.rb
override :chef,   version: "11.10.0"
```

The value of version can be any valid git reference (e.g., tag,
branch name, or SHA).

Kitchen-based Build Environment
-------------------------------
Every Omnibus project ships will a project-specific [Berksfile](http://berkshelf.com/)
that will allow you to build your omnibus projects on all of the projects listed
in the `.kitchen.yml`. You can add/remove additional platforms as needed by
changing the list found in the `.kitchen.yml` `platforms` YAML stanza.

This build environment is designed to get you up-and-running quickly. However,
there is nothing that restricts you to building on other platforms. Simply use
the [omnibus cookbook](https://github.com/opscode-cookbooks/omnibus) to setup
your desired platform and execute the build steps listed above.

The default build environment requires Test Kitchen and VirtualBox for local
development. If you don't have Test Kitchen installed on your workstation we
recommend installing the
[latest version of ChefDK package for your platform](http://www.getchef.com/downloads/chef-dk/mac/).
Test Kitchen also exposes the ability to provision instances using various cloud
providers like AWS, DigitalOcean, or OpenStack. For more information, please see
the [Test Kitchen documentation](http://kitchen.ci).

Once you have tweaked your `.kitchen.yml` (or `.kitchen.local.yml`) to your
liking, you can bring up an individual build environment using the `kitchen`
command.

```shell
$ kitchen converge <PROJECT>-ubuntu-12.04
```

Then login to the instance and build the project as described in the Usage
section:

```shell
$ kitchen login ubuntu-12.04
[vagrant@ubuntu...] $ cd omnbius-chef
[vagrant@ubuntu...] $ bundle install --binstubs
[vagrant@ubuntu...] $ ...
[vagrant@ubuntu...] $ bundle exec omnibus build <PROJECT NAME>
```

If you are building the Chef project you will need to purge the Chef package
that was used to provision the VM:

```shell
[vagrant@ubuntu...] $ sudo rm -rf /opt/chef
[vagrant@ubuntu...] $ sudo mkdir -p /opt/chef
[vagrant@ubuntu...] $ sudo chown vagrant /opt/chef
```

For a complete list of all commands and platforms, run `kitchen list` or
`kitchen help`.

## License

See the LICENSE file for details.

Copyright (c) 2012 Opscode, Inc.
License: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
