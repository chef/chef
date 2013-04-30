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
packages for a specific version of Chef by leveraging the `CHEF_GIT_REV`
environment variable. The value can be any valid git reference (e.g., tag,
branch name, or SHA).

For example, to build a package for Chef 11.4.4 you would run the following
command:

```shell
CHEF_GIT_REV=11.4.4 bin/omnibus build project chef
```
The `CHEF_GIT_REV` environment variable is also respected when using the
Vagrant-based build lab documented below.

## Vagrant-based Virtualized Build Labs

Please note this build-lab is only meant to get you up and running quickly;
there's nothing inherent in Omnibus that restricts you to just building
packages for the platforms below. See an individual Vagrantfile to add new
platforms to your build lab.

The only requirements for standing up this virtualized build lab are:

* VirtualBox - native packages exist for most platforms and can be downloaded
from the [VirtualBox downloads page](https://www.virtualbox.org/wiki/Downloads).
* Vagrant 1.2.1+ - native packages exist for most platforms and can be downloaded
from the [Vagrant downloads page](http://downloads.vagrantup.com/).

The [vagrant-berkshelf](https://github.com/RiotGames/vagrant-berkshelf) and
[vagrant-omnibus](https://github.com/schisamo/vagrant-omnibus) Vagrant plugins
are also required and can be installed easily with the following commands:

```shell
$ vagrant plugin install vagrant-berkshelf
$ vagrant plugin install vagrant-omnibus
```

This project ships will a project-specific [Berksfile](http://berkshelf.com/)
and [Vagrantfile](http://www.vagrantup.com/) that will allow you to build your
projects on the following platforms:

### Linux

The following distibutions are currently supported by the Linux build lab:

* CentOS 5 64-bit
* CentOS 6 64-bit
* Ubuntu 10.04 64-bit
* Ubuntu 11.04 64-bit
* Ubuntu 12.04 64-bit

```shell
$ cd vagrant/linux
$ vagrant up
```

If you would like to build a package for a single platform the command looks like this:

```shell
$ cd vagrant/linux
$ vagrant up PLATFORM
```

The complete list of valid platform names can be viewed with the
`vagrant status` command.

### FreeBSD

The FreeBSD guest for Vagrant only supports folder mounting via NFS. This means
the FreeBSD Build Lab can only be started up on a platform that has `nfsd`
installed, the NFS server daemon. This comes pre-installed on Mac OS X, and is
typically a simple package install on Linux.

SO..if you are on a *nix platform you should be able to just run:

```shell
$ cd vagrant/freebsd
$ vagrant up
```

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
