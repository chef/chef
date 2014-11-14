# Chef Developer Repo

This repository contains some basic cookbooks to test chef while you're hacking away.

You can run these recipes on your box with:

```
$ bundle install
$ bundle exec chef-client -z -o "recipe[audit_test::default]" -c dev-repo/dev-config.rb
```

Or you can provision a VM using the kitchen configuration and run these tests:

```
$ kitchen converge chef-ubuntu-1210
$ kitchen login chef-ubuntu-1210
$ export PATH=/opt/chef/bin:/opt/chef/embedded/bin:$PATH
$ cd ~/chef
$ bundle install
$ bundle exec chef-client -z -o "recipe[audit_test::default]" -c dev-repo/dev-config.rb

```
