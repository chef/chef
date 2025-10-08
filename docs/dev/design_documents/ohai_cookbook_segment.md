# Add Ohai cookbook segment

Support Ohai plugins under an `ohai` top level directory in cookbooks.  Load all
Ohai plugins in all synchronized cookbooks after cookbook synchronization.

## Motivation

    As a Chef User,
    I want to have my custom Ohai plugins loaded on first bootstrap,
    So I don't have to run chef twice.

    As a Chef User,
    I want my Ohai plugins loaded before attributes and compile/converge mode,
    So I can use them without worrying about cookbook execution ordering.

    As a Chef User,
    I want my Ohai plugins synchronized with my cookbooks,
    So that I don't incur more unavoidable round-trips to the Chef Server.

    As a Chef Developer,
    I want Ohai plugins as a first-class object,
    So that I don't have to compile recipes to discover templates that drop plugins.

## Specification

The "segments" of a cookbook will be extended to include an "ohai" segment.  In this segment, there will be plugins, which are intended to be copied to the Ohai `plugin_path`. All files in this segment will be copied, recursively, maintaining directory structure.

In the `Chef::RunContext::CookbookCompiler#compile` method, a phase will be added after `compile_libraries` and before `compile_attributes`, which will copy the Ohai plugins from the cookbook segment and will load all of the discovered plugins.

The plugins will be copied from `<cookbookname>/ohai` into `/etc/chef/ohai/cookbook-plugins/<cookbookname>` as their top level directory (recursively). The state of the entire
subdirectory tree under `/etc/chef/ohai/cookbook-plugins` will be managed fully by chef-client so that any files which are not synchronized by chef-client will be removed, so
that removal of a plugin from a cookbook or removal of the cookbook from `run_list` will result in the plugin being removed on the target host.

The plugins directory will work similarly to libraries and other directions, in that there will be no control over the inclusion of plugins below the level of the inclusion of the cookbook itself in the `run_list`.

When plugins override other plugins on loading, and in particular when cookbook plugins override core plugins, they should WARN the user. This will address the case where a user has included a custom plugin and Ohai is later extended with similar functionality in the same namespace. The custom plugin should take precedence for backwards compatibility. There should be a way to silence the warning with a DSL method added to the custom plugin.