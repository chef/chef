# Developer's Guide to Knife

## Overview

knife is a command-line tool that provides an interface between a local Chef repository and the Chef Infra Server. Read more about knife [here](https://docs.chef.io/workstation/knife/).

## Development setup

To setup knife for development-
1. Fork and clone the [chef repository](https://github.com/chef/chef) in GitHub.
1. Ensure you have Ruby 3.x installed on your system. You will additionally need tools such as `make` and `gcc`. These are usually already present on most Linux distributions or on your macOS.
1. Navigate to chef/knife and run `bundle install`.
1. You can run knife commands in this setup by executing `bundle exec knife <subcommand> <argument> <options>`.
1. Refer to the article [Setting up Knife](https://docs.chef.io/workstation/knife_setup/) for help with necessary configuration.
1. byebug or your preferred Ruby debugger can be used to step through the execution flow.

## Execution Flow

The execution starts by instantiating the `Chef::Application::Knife` class with its `run` instance method being invoked. Ref [knife/bin/knife](https://github.com/chef/chef/blob/main/knife/bin/knife). The `Chef::Application` class helps work with CLI command options through the `Mixlib::CLI` module. This `run` instance method in turn invokes the `Chef::Knife`'s `run` class method. `Chef::Knife` acts as the base class for some of the classes associated with knife subcommands such as `Chef::Knife::NodeCreate`, `Chef::Knife::SupermarketList`, `Chef::Knife::Bootstrap`, etc. The role of `Chef::Knife` is summarized here:

- Identify the subcommand supplied.
- Merge subcommand specific CLI options, if any.
- Load dependencies to help subclass perform subcommand action.
- Instantiate the associated subclass.
- Set up a local-mode Chef server if chef-zero is configured.
- Run the subcommand action.

With this design, most classes associated with subcommands only need to implement the `run` instance method, while the setup and context is broadly taken care of by `Chef::Knife`. The `Chef::Knife::Bootstrap` class is somewhat of an exception here, as its functionality requires a rather elaborate set of methods and additional classes. That said, not all classes associated with subcommands directly inherit `Chef::Knife`. These inherit the `Chef::ChefFS::Knife` class of the `Chef::ChefFS` module. `Chef::ChefFS::Knife` happens to be a subclass of `Chef::Knife` to avoid redundancy. `Chef::ChefFS` [module](https://www.rubydoc.info/gems/chef/Chef/ChefFS) encapsulates classes and modules that help map the Chef server objects to the local chef repository using a file/directory analogy. It also employs a parallel thread utility to speed up command execution. Examples of such Knife classes are `Chef::Knife::Upload`, `Chef::Knife::Diff` & `Chef::Knife::List`.

## Knife Bootstrap

As `bootstrap` is a remote/distributed operation, there are several phases to it:
- Set up knife plugin, if needed.
- Validate if the specified protocol to connect to client node is supported.
- Validate if the transport and policy options are correct.
- Establish connection with the server where chef client is to be deployed. The connection is identified by a `Chef::Knife::Bootstrap::TrainConnector` instance.
- Define the `Chef::Node` instance that represents the server & update this object in Chef server. The class `Chef::Knife::Bootstrap::ClientBuilder` encapsulates this functionality.
- Update the Chef vault item(s) so the new node has access to those. The class `Chef::Knife::Bootstrap::ChefVaultHandler` encapsulates this functionality.
- Prepare the `bootstrap.bat` or `bootstrap.sh` script based on the bootstrap template.
- Copy and execute the bootstrap script on the remote server.

## Knife Plugins

The choice of mapping subcommand action to `Chef::Knife` subclass makes it easy to author knife custom plugins. These can help with extending knife capabilities for specific cloud platforms or customize knife behavior for a subset of subcommands. Follow the instructions [here](https://docs.chef.io/workstation/plugin_knife_custom/) to develop your own knife plugin. Detailed documentation on writing knife cloud plugins is available [here](https://github.com/chef/knife-cloud/blob/main/README.md).
