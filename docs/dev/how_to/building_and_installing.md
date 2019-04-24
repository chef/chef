# Building and Installing

Chef Infra can be built and installed in two distinct ways:
	- A gem built from this repository and installed into your own Ruby installation
	- A system native package containing its own Ruby built using our Omnibus packaging system

**NOTE:** As an end user, please download the [Chef Infra package](https://downloads.chef.io/chef) for managing systems, or the [Chef Workstation package](https://downloads.chef.io/chef-workstation) for authoring Chef cookbooks and administering your Chef infrastructure.

We do not recommend for end users to install Chef from gems or build from source. The following instructions apply only to those developing the Chef Infra client.

## Building the Gem

### Prerequisite

- git
- C compiler, header files, etc.
- Ruby 2.5 or later
- Bundler gem

**NOTE:** Chef supports a large number of platforms, and there are many different ways to manage Ruby installs on each of those platforms. We assume you will install Ruby in a way appropriate for your development platform, but do not provide instructions for setting up Ruby.

### Building / Installing

Once you have your development environment configured, you can clone the Chef repository and install Chef:

```bash
git clone https://github.com/chef/chef.git
cd chef
bundle install
bundle exec rake install
```

## Building the Full System Native Package

To build Chef as a standalone package, we use the [omnibus](omnibus/README.md) packaging system.

To build:

```bash
git clone https://github.com/chef/chef.git
cd chef/omnibus
bundle install
bundle exec omnibus build chef
```

The prerequisites necessary to run omnibus itself are not documented in this repository. See the [Omnibus project repository](https://github.com/chef/omnibus) for additional details.
