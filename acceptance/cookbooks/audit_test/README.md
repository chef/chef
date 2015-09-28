# audit_test

This cookbook has some basic recipes to test audit mode.

In order to run these tests on your dev box:

```
$ bundle install
$ bundle exec chef-client -c kitchen-tests/.chef/client.rb -z -o audit_test::default -l debug
```

Expected JSON output for the tests will be printed to `debug` log.
