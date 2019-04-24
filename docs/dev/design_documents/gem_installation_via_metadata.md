# Enable gem dependencies in cookbook metadata

Support a 'gem' DSL method for cookbook metadata to create a dependency on a rubygem.  The
gem will be installed via `chef_gem` after all the cookbooks are synchronized, but before any
other cookbook loading is done.

## Motivation

    As a Chef User,
    I want to be able to use additional gems in libraries, attributes and resources,
    and to avoid complex workarounds and double-run converges.

## Specification

Allow users to specify additional gem dependencies like:

```ruby
gem "poise"
gem "chef-sugar"
gem "chef-provisioning"
```

In the `Chef::RunContext::CookbookCompiler#compile` method, a phase will be added before `compile_libraries`. This phase will install all of the gem declarations from all of the synchronized cookbooks before any other cookbook code is compiled.

The implementation will use an in-memory bundler Gemfile which is constructed against all gem statements in all cookbooks which are in the `run_list`, solved
at the same time.  The syntax of the 'gem' statement will support the bundler gem syntax, with the qualification of since the syntax is compiled into metadata.json, that arbitrary ruby code will be expanded at cookbook upload time.

The resulting gemset bundle will be installed into the LIBPATH of the running chef-client.  This may either be directly into the base ruby libraries (per current `chef_gem` behavior), or into a custom location with the LIBPATH of the chef-client extended to use that location--as an open implementation question.

The normal Gemfile `requires` tag may be used by users to autoload files out of gems.
