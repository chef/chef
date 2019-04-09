---
title: Data Collector
---

# Data Collector Design

The Data Collector design and API is covered in:

https://github.com/chef/chef-rfc/blob/master/rfc077-mode-agnostic-data-collection.md

This document will focus entirely on the nuts and bolts of the Data Collector

## Action Collection Integration

Most of the work is done by a separate Action Collection to track the actions of Chef resources.  If the Data Collector is not enabled, it never registers with the
Action Collection and no work will be done by the Action Collection to track resources.

## Additional Collected Information

The Data Collector also collects:

- the expanded run list
- deprecations
- the node
- formatted error output for exceptions

Most of this is done through hooking events directly in the Data Collector itself.  The ErrorHandlers module is broken out into a module which is directly mixed into
the Data Collector to separate that concern out into a different file (it is straightforward with fairly little state, but is just a lot of hooked methods).

## Basic Configuration Modes

### Configured for Automate

Do nothing.  The URL is constructed from the base `Chef::Config[:chef_server_url]`, auth is just Chef Server API authentication, and the default behavior is that it
is configured.

### Configured to Log to a File

Setup a file output location, no token is necessary:

```
Chef::Config[:data_collector][:output_locations] = { files:  [ "/Users/lamont/data_collector.out" ] }
```

Note the fact that you can't assign to `Chef::Config[:data_collector][:output_locations][:files]` and will NoMethodError if you try.

### Configured to Log to a Non-Chef Server Endpoint

Setup a server url, requiring a token:

```
Chef::Config[:data_collector][:server_url] = "https://chef.acme.local/myendpoint.html"
Chef::Config[:data_collector][:token] = "mytoken"
```

This works for chef-clients which are configured to hit a chef server, but use a custom non-Chef-Automate endpoint for reporting, or for chef-solo/zero users.

XXX: There is also the `Chef::Config[:data_collector][:output_locations] = { uri: [ "https://chef.acme.local/myendpoint.html" ] }` method -- which is going to behave
differently, particularly on non-chef-solo use cases.  In that case the Data Collector `server_url` will still be automatically derived from the `chef_server_url` and
the Data Collector will attempt to contact that endpoint, but with the token being supplied it will use that and will not use Chef Server authentication, and the
server should 403 back, and if `raise_on_failure` is left to the default of false then it will simply drop that failure and continue without raising, which will
appear to work, and output will be send to the configured `output_locations`.  Note that the presence of a token flips all external URIs to using the token so that
it is **not** possible to use this feature to talk to both a Chef Automate endpoint and a custom URI reporting endpoint (which would seem to be the most useful of an
incredibly marginally useful feature and it does not work).  But given how hopelessly complicated this is, the recommendation is to use the `server_url` and to avoid
using any `url` options in the `output_locations` since that feature is fairly poorly designed at this point in time.

## Resiliency to Failures

The Data Collector in Chef >= 15.0 is resilient to failures that occur anywhere in the main loop of the `Chef::Client#run` method.  In order to do this there is a lot
of defensive coding around internal data structures that may be nil (e.g. failures before the node is loaded will result in the node being nil).  The spec tests for
the Data Collector now run through a large sequence of events (which must, unfortunately, be manually kept in sync with the events in the Chef::Client if those events
are ever 'moved' around) which should catch any issues in the Data Collector with early failures.  The specs should also serve as documentation for what the messages
will look like under different failure conditions.  The goal was to keep the format of the messages to look as near as possible to the same schema as possible even
in the presence of failures.  But some data structures will be entirely empty.

When the Data Collector fails extraordinarily early it still sends both a start and an end message.  This will happen if it fails so early that it would not normally
have sent a start message.

## Decision to Be Enabled

This is complicated due to over-design and is encapsulated in the `#should_be_enabled?` method and the ConfigValidation module.  The `#should_be_enabled?` message and
ConfigValidation should probably be merged into one renamed Config module to isolate the concern of processing the Chef::Config options and doing the correct thing.

## Run Start and Run End Message modules

These are separated out into their own modules, which are very deliberately not mixed into the main Data Collector.  They use the Data Collector and Action Collection
public interfaces.  They are stateless themselves.  This keeps the collaboration between them and the Data Collector very easy to understand.  The start message is
relatively simple and straightforwards.  The complication of the end message is mostly due to walking through the Action Collection and all the collected action
records from the entire run, along with a lot of defensive programming to deal with early errors.

## Relevant Event Sequence

As it happens in the actual chef-client run:

1. `events.register(data_collector)`
2. `events.register(action_collection)`
3. `run_status.run_id = request_id`
4. `events.run_start(Chef::VERSION, run_status)`
  * failures during registration will cause `registration_failed(node_name, exception, config)` here and skip to #13
  * failures during node loading will cause `node_load_failed(node_name, exception, config)` here and skip to #13
5. `events.node_load_success(node)`
6. `run_status.node = node`
  * failures during run list expansion will cause `run_list_expand_failed(node, exception)` here and skip to #13
7. `events.run_list_expanded(expansion)`
8. `run_status.start_clock`
9. `events.run_started(run_status)`
  * failures during cookbook resolution will cause `events.cookbook_resolution_failed(node, exception)` here and skip to #13
  * failures during cookbook synch will cause `events.cookbook_sync_failed(node, exception)` and skip to #13
10. `events.cookbook_compilation_start(run_context)`
11. < the resource events happen here which hit the Action Collection, may throw any of the other failure events >
12. `events.converge_complete` or `events.converge_failed(exception)`
13. `run_status.stop_clock`
14. `run_status.exception = exception` if it failed
15. `events.run_completed(node, run_status)` or `events.run_failed(exception, run_status)`
