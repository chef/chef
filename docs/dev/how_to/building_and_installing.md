# Building and Installing

Chef Infra can be built and installed in two distinct ways:

- A gem built from this repository and installed into your own Ruby installation
- A Habitat package containing the runtime and dependencies used for Chef Infra Client distribution

**NOTE:** As an end user, please download the [Chef Infra package](https://www.chef.io/downloads/tools/infra-client) for managing systems, or the [Chef Workstation package](https://www.chef.io/downloads/tools/workstation) for authoring Chef cookbooks and administering your Chef infrastructure.

We do not recommend for end users to install Chef from gems or build from source. The following instructions apply only to those developing the Chef Infra client.

## Building the Gem

### Prerequisite

- git
- C compiler, header files, etc.
- Ruby 2.6 or later

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

To build Chef Infra Client as a distributed package, we use the Habitat packaging workflow in this repository. The package definitions live under the habitat directory and official package builds are produced through the Buildkite and Expeditor Habitat pipelines.
