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
$ bin/omnibus build project chef
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

## Vagrant-based Virtualized Build Labs

Every Omnibus project ships will a project-specific Berksfile and Vagrantfile that will allow you to build your projects on the following platforms:

* CentOS 5 64-bit
* CentOS 6 64-bit
* FreeBSD 8.3 64-bit
* FreeBSD 9.1 64-bit
* SmartOS Base 1310
* Ubuntu 10.04 64-bit
* Ubuntu 11.04 64-bit
* Ubuntu 12.04 64-bit

Please note this build-lab is only meant to get you up and running quickly;
there's nothing inherent in Omnibus that restricts you to just building
packages for the platforms below. See an individual Vagrantfile to add new
platforms to your build lab.

The only requirements for standing up this virtualized build lab are:

* VirtualBox - native packages exist for most platforms and can be downloaded
from the [VirtualBox downloads page](https://www.virtualbox.org/wiki/Downloads).
* Vagrant 1.2.1+ - native packages exist for most platforms and can be downloaded
from the [Vagrant downloads page](http://downloads.vagrantup.com/).
* NOTE: If you are building omnibus-chef for any FreeBSD release - you must be
using Vagrant > 1.5.0 which includes multiple FreeBSD fixes.

The [vagrant-berkshelf](https://github.com/RiotGames/vagrant-berkshelf) and
[vagrant-omnibus](https://github.com/schisamo/vagrant-omnibus) Vagrant plugins
are also required and can be installed easily with the following commands:

```shell
$ vagrant plugin install vagrant-berkshelf
$ vagrant plugin install vagrant-omnibus
```


Once the pre-requisites are installed you can build your package across all platforms with the following command:

```shell
$ vagrant up
```

If you would like to build a package for a single platform the command looks like this:

```shell
$ vagrant up PLATFORM
```

The complete list of valid platform names can be viewed with the `vagrant status` command.

The FreeBSD guest for Vagrant only supports folder mounting via NFS. This means
the FreeBSD Build Lab can only be started up on a platform that has `nfsd`
installed, the NFS server daemon. This comes pre-installed on Mac OS X, and is
typically a simple package install on Linux.

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
