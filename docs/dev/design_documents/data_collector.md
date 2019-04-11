---
title: Data Collector
---

# Data Collector Design

## Motivation

    As a Chef user who uses both Chef Client Mode and Chef Solo Mode (including the mode commonly known as "Chef Client Local Mode"),
    I want to be able to collect data about my entire fleet regardless of their client operation type,
    so that I may better understand the impacts of my changes and may better detect failures.

### Definitions

To eliminate ambiguity and confusion, the following terms are used throughout this RFC:

 * **Chef**: the tool used to automate your system.
 * **Chef Client Mode**: Chef configured in "client mode" where a Chef Server is used to provide Chef its resources and artifacts
 * **Chef Solo Mode**: Chef configured in a mode that utilizes a local Chef Zero server. Formerly known as "Chef Client Local Mode" (run as `chef-client --local-mode`)
 * **Chef Solo Legacy Mode**: Chef in the pre 12.10 Solo operational mode (run as `chef-solo`) or Chef run as `chef-solo --legacy-mode`

### Specification

Similar to how data is collected and reported for Chef Reporting, we expect to implement a new EventDispatch class/instance that collects data about the Chef run and reports it accordingly. Unlike Chef Reporting, the server that receives this data is **not** running on the Chef Server, allowing users to utilize this function whether they use Chef Server or not. No new data collection methods are expected to be implemented as a result of this change; this change serves to implement a generic way to report the collected data in a "webhook-like" fashion to a non-Chef-Server receiver.

The implementation must work with Chef running in any mode:

 * Chef Client Mode
 * Chef Solo Mode
 * Chef Solo Legacy Mode

#### Protocol and Authentication

All payloads will be sent to the Data Collector server via HTTP POST to the URL specified in the `data_collector_server_url` configuration parameter. Users should be encouraged to use a TLS-protected endpoint.

Optionally, payloads may also be written out to multiple HTTP endpoints or JSON files on the local filesystem (of the node running `chef-client`) by specifying the `data_collector_output_locations` configuration parameter.

For the initial implementation, transmissions to the Data Collector server can optionally be authenticated with the use of a pre-shared token, which will be sent in a HTTP header. Given that the receiver is not the Chef Server, existing methods of using a Chef `client` key to authenticate the request are unavailable.

#### Configuration

The configuration required for this new functionality can be placed in the `client.rb` or any other `Chef::Config`-supported location (such as a client.d or solo.d directory).

##### Parameters

 * **data\_collector\_server\_url**: required*. The full URL to the data collector server API. All messages will be POST'd to this URL. The Data Collector class will be registered and enabled if this config parameter is specified. * If the `data_collector_output_locations` configuration parameter is specified, this setting may be omitted.
 * **data\_collector\_token**: optional. A pre-shared token that, if present, will be passed as an HTTP header named `x-data-collector-token` to the Data Collector server. The server can choose to accept or reject the data posted based on the token or lack thereof.
 * **data\_collector\_mode**: The Chef mode in which the Data Collector will be enabled. For example, you may wish to only enable the Data Collector when running in Chef Solo Mode. Must be one of: `:solo`, `:client`, or `:both`. The `:solo` value is used for Chef operating in Chef Solo Mode or Chef Solo Legacy Mode. Default: `:both`.
 * **data\_collector\_raise\_on\_failure**: If true, the Chef run will fatally exit if it is unable to successfully POST to the Data Collector server. Default: `false`.
 * **data\_collector\_output\_locations**: optional. An array of URLs and/or file paths to which data collection payloads will also be written. This may be used without specifying the `data_collector_server_url` configuration parameter.

### Schemas

For the initial implementation, three JSON schemas will be utilized.

##### Action Schema

The Action Schema is used to notify when a Chef object changes. In our case, the primary use will be to update the Data Collector server with the current node object.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "description": "Data Collector - action schema",
  "properties": {
    "entity_name": {
      "description": "The name of the entity",
      "type": "string"
    },
    "entity_type": {
      "description": "The type of the entity",
      "type": "string",
      "enum": [
        "bag",
        "client",
        "cookbook",
        "environment",
        "group",
        "item",
        "node",
        "organization",
        "permission",
        "role",
        "user",
        "version"]
    },
    "entity_uuid": {
      "description": "Unique ID identifying this object, which should persist across runs and invocations",
      "type": "string",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"
    },
    "id": {
      "description": "Globally Unique ID for this message",
      "type": "string",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"
    },
    "message_version": {
      "description": "Message Version",
      "type": "string",
      "enum": [
        "1.1.0"
      ]
    },
    "message_type": {
      "description": "Message Type",
      "type": "string",
      "enum": ["action"]
    },
    "organization_name": {
      "description": "It is the name of the org on which the run took place",
      "type": ["string", "null"]
    },
    "recorded_at": {
      "description": "It is the ISO timestamp when the action happened",
      "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-5][0-9]:[0-9]{2}Z$",
      "type": "string"
    },
    "remote_hostname": {
      "description": "The remote hostname which initiated the action",
      "type": "string"
    },
    "requestor_name": {
      "description": "The name of the client or user that initiated the action",
      "type": "string"
    },
    "requestor_type": {
      "description": "Was the requestor a client or user?",
      "type": "string",
      "enum": ["client", "user"]
    },
    "run_id": {
      "description": "The run ID of the run in which this node object was updated",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
      "type": "string"
    },
    "service_hostname": {
      "description": "The FQDN of the Chef server, if appropriate",
      "type": "string"
    },
    "source": {
      "description": "The tool / client mode that initiated the action. Note that 'chef_solo' includes Chef Solo Mode and Chef Solo Legacy Mode.",
      "type": "string",
      "enum": ["chef_solo", "chef_client"]
    },
    "task": {
      "description": "What action was performed?",
      "type": "string",
      "enum": ["associate", "create", "delete", "dissociate", "invite", "reject", "update"]
    },
    "user_agent": {
      "description": "The User-Agent of the requestor",
      "type": "string"
    },
    "data": {
      "description": "The payload containing the entire request data",
      "type": "object"
    }
  },
  "required": [
    "entity_name",
    "entity_type",
    "entity_uuid",
    "id",
    "message_type",
    "message_version",
    "organization_name",
    "recorded_at",
    "remote_hostname",
    "requestor_name",
    "requestor_type",
    "run_id",
    "service_hostname",
    "source",
    "task",
    "user_agent"
  ],
  "title": "ActionSchema",
  "type": "object"
}
```

The `data` field will contain the value of the object on which an action took place.

##### Run Start Schema

The Run Start Schema will be used by Chef to notify the data collection server at the start of the Chef run.

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "description": "Data Collector - Runs run_start schema",
  "properties": {
    "chef_server_fqdn": {
      "description": "It is the FQDN of the chef_server against whch current reporting instance runs",
      "type": "string"
    },
    "entity_uuid": {
      "description": "Unique ID identifying this node, which should persist across Chef runs",
      "type": "string",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"
    },
    "id": {
      "description": "It is the internal message id for the run",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
      "type": "string"
    },
    "message_version": {
      "description": "Message Version",
      "type": "string",
      "enum": [
        "1.0.0"
      ]
    },
    "message_type": {
      "description": "It defines the type of message being sent",
      "type": "string",
      "enum": ["run_start"]
    },
    "node_name": {
      "description": "It is the name of the node on which the run took place",
      "type": "string"
    },
    "organization_name": {
      "description": "It is the name of the org on which the run took place",
      "type": "string"
    },
    "run_id": {
      "description": "It is the runid for the run",
      "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
      "type": "string"
    },
    "source": {
      "description": "The tool / client mode that initiated the action. Note that 'chef_solo' includes Chef Solo Mode and Chef Solo Legacy Mode.",
      "type": "string",
      "enum": ["chef_solo", "chef_client"]
    },
    "start_time": {
      "description": "It is the ISO timestamp of when the run started",
      "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
      "type": "string"
    }
  },
  "required": [
    "chef_server_fqdn",
    "entity_uuid",
    "id",
    "message_version",
    "message_type",
    "node_name",
    "organization_name",
    "run_id",
    "source",
    "start_time"
  ],
  "title": "RunStartSchema",
  "type": "object"
}
```

##### Run End Schema

The Run End Schema will be used by Chef Client to notify the data collection server at the completion of the Chef Client's converge phase, and to report data on the Chef Client run, including resources changed and any errors encountered.

```json
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "Data Collector - Runs run_converge schema",
    "properties": {
        "chef_server_fqdn": {
            "description": "It is the FQDN of the chef_server against whch current reporting instance runs",
            "type": "string"
        },
        "end_time": {
            "description": "It is the ISO timestamp of when the run ended",
            "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
            "type": "string"
        },
        "entity_uuid": {
          "description": "Unique ID identifying this node, which should persist across Chef Client/Solo runs",
          "type": "string",
          "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"
        },
        "error": {
            "description": "It has the details of the error in the run if any",
            "type": "object"
        },
        "expanded_run_list": {
            "description": "The expanded run list object from the node",
            "type": "object"
        },
        "id": {
            "description": "It is the internal message id for the run",
            "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
            "type": "string"
        },
        "message_type": {
            "description": "It defines the type of message being sent",
            "type": "string",
            "enum": ["run_converge"]
        },
        "message_version": {
            "description": "Message Version",
            "type": "string",
            "enum": [
                "1.1.0"
            ]
        },
        "node": {
            "description": "The node object after the converge completed",
            "type": "object"
        },
        "node_name": {
            "description": "Node Name",
            "type": "string",
            "format": "node-name"
        },
        "organization_name": {
            "description": "Organization Name",
            "type": "string"
        },
        "resources": {
            "description": "This is the list of all resources for the run",
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "after": {
                        "description": "Final State of the resource",
                        "type": "object"
                    },
                    "before": {
                        "description": "Initial State of the resource",
                        "type": "object"
                    },
                    "cookbook_name": {
                        "description": "Name of the cookbook that initiated the change",
                        "type": "string"
                    },
                    "cookbook_version": {
                        "description": "Version of the cookbook that initiated the change",
                        "type": "string",
                        "pattern": "^[0-9]*\\.[0-9]*(\\.[0-9]*)?$"
                    },
                    "delta": {
                        "description": "Difference between initial and final value of resource",
                        "type": "string"
                    },
                    "duration": {
                        "description": "Duration of the run consumed by processing of this resource, in milliseconds",
                        "type": "string"
                    },
                    "id": {
                        "description": "Resource ID",
                        "type": "string"
                    },
                    "ignore_failure": {
                        "description": "the ignore_failure setting on a resource, indicating if a failure on this resource should be ignored",
                        "type": "boolean"
                    },
                    "name": {
                        "description": "Resource Name",
                        "type": "string"
                    },
                    "result": {
                        "description": "The action taken on the resource",
                        "type": "string"
                    },
                    "status": {
                        "description": "Status indicating how Chef processed the resource",
                        "type": "string",
                        "enum": [
                          "failed",
                          "skipped",
                          "unprocessed",
                          "up-to-date",
                          "updated"
                        ]
                    },
                    "type": {
                        "description": "Resource Type",
                        "type": "string"
                    }
                },
                "required": [
                    "after",
                    "before",
                    "delta",
                    "duration",
                    "id",
                    "ignore_failure",
                    "name",
                    "result",
                    "status",
                    "type"
                ]
            }
        },
        "run_id": {
            "description": "It is the runid for the run",
            "pattern": "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$",
            "type": "string"
        },
        "run_list": {
            "description": "It is the runlist for the run",
            "type": "array",
            "items": {
                "type": "string"
            }
        },
        "source": {
            "description": "The tool / client mode that initiated the action. Note that 'chef_solo' includes Chef Solo Mode and Chef Solo Legacy Mode.",
            "type": "string",
            "enum": ["chef_solo", "chef_client"]
        },
        "start_time": {
            "description": "It is the ISO timestamp of when the run started",
            "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$",
            "type": "string"
        },
        "status": {
            "description": "It gives the status of the run",
            "type": "string",
            "enum": [
                "success",
                "failure"
            ]
        },
        "total_resource_count": {
            "description": "It is the total number of resources for the run",
            "type": "integer",
            "minimum": 0
        },
        "updated_resource_count": {
            "description": "It is the number of updated resources during the course of the run",
            "type": "integer",
            "minimum": 0
        }
    },
    "required": [
        "chef_server_fqdn",
        "entity_uuid",
        "id",
        "end_time",
        "expanded_run_list",
        "message_type",
        "message_version",
        "node",
        "node_name",
        "organization_name",
        "resources",
        "run_id",
        "run_list",
        "source",
        "start_time",
        "status",
        "total_resource_count",
        "updated_resource_count"
    ],
    "title": "RunEndSchema",
    "type": "object"
}
```

## Technical Implementation

The remainder of document will focus entirely on the nuts and bolts of the Data Collector.

### Action Collection Integration

Most of the work is done by a separate Action Collection to track the actions of Chef resources.
If the Data Collector is not enabled, it never registers with the Action Collection and no work will be done by the Action Collection to track resources.

### Additional Collected Information

The Data Collector also collects:

- the expanded run list
- deprecations
- the node
- formatted error output for exceptions

Most of this is done through hooking events directly in the Data Collector itself. The ErrorHandlers module is broken out into a module, which is directly mixed into the Data Collector, to separate that concern out into a different file. This ErrorHandlers module is straightforward with fairly little state, but involves a lot of hooked methods.

### Basic Configuration Modes

#### Configured for Automate

Do nothing. The URL is constructed from the base `Chef::Config[:chef_server_url]`, `auth` is just Chef Server API authentication, and the default behavior is that it is configured.

#### Configured to Log to a File

Setup a file output location, no token is necessary:

```
Chef::Config[:data_collector][:output_locations] = { files:  [ "/Users/lamont/data_collector.out" ] }
```

Note the fact that you can't assign to `Chef::Config[:data_collector][:output_locations][:files]` and will NoMethodError if you try.

#### Configured to Log to a Non-Chef Server Endpoint

Setup a server url, requiring a token:

```
Chef::Config[:data_collector][:server_url] = "https://chef.acme.local/myendpoint.html"
Chef::Config[:data_collector][:token] = "mytoken"
```

This works for chef-clients, which are configured to hit a Chef server, but use a custom non-Chef-Automate endpoint for reporting, or for chef-solo/zero users.

XXX: There is also the `Chef::Config[:data_collector][:output_locations] = { uri: [ "https://chef.acme.local/myendpoint.html" ] }` method, which will behave differently, particularly on non-chef-solo use cases. 
In that case, the Data Collector `server_url` will still be automatically derived from the `chef_server_url` and the Data Collector will attempt to contact that endpoint. 
But with the token being supplied, the Data Collector will use that token and will not use Chef Server authentication. 
Thus, the server should 403 back.
Also, if `raise_on_failure` is left to the default of `false`, then the Data Collector will simply drop that failure and continue without raising, which will appear to work, and output will be send to the configured `output_locations`. 
Note that the presence of a token flips all external URIs to using the token. So it is **not** possible to use this feature to talk to both a Chef Automate endpoint and a custom URI reporting endpoint.
This would seem to be the most useful of an incredibly marginally useful feature and it does not work. 
But given how hopelessly complicated this is, the recommendation is to use the `server_url` and to avoid using any `url` options in the `output_locations` since that feature is fairly poorly designed at this point in time.

### Resiliency to Failures

The Data Collector in Chef >= 15.0 is resilient to failures that occur anywhere in the main loop of the `Chef::Client#run` method. 
In order to do this, there is a lot of defensive coding around internal data structures that may be `nil`. (e.g. failures before the node is loaded will result in the node being nil.)
The spec tests for the Data Collector now run through a large sequence of events -- which must, unfortunately, be manually kept in sync with the events in the Chef::Client if those events are ever 'moved' around -- which should catch any issues in the Data Collector with early failures. 
The specs should also serve as documentation for what the messages will look like under different failure conditions. 
The goal was to keep the format of the messages to look as near as possible to the same schema as possible, even in the presence of failures, but some data structures will be entirely empty.

When the Data Collector fails extraordinarily early, it still sends both a start and an end message. 
This will happen if it fails so early that it would not normally have sent a start message.

### Decision to Be Enabled

This is complicated due to over-design and is encapsulated in the `#should_be_enabled?` method and the ConfigValidation module. The `#should_be_enabled?` message and
ConfigValidation should probably be merged into one renamed Config module to isolate the concern of processing the Chef::Config options and of doing the correct thing.

### Run Start and Run End Message modules

These are separated out into their own modules, which are very deliberately not mixed into the main Data Collector.
They use the Data Collector and Action Collection public interfaces. 
They are stateless themselves.
This keeps the collaboration between them and the Data Collector very easy to understand.
The start message is relatively simple and straightforwards.
The complication of the end message is mostly due to walking through the Action Collection and all the collected action records from the entire run, along with a lot of defensive programming to deal with early errors.

### Relevant Event Sequence

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
11. < the resource events happen here, which hit the Action Collection, may throw any of the other failure events >
12. `events.converge_complete` or `events.converge_failed(exception)`
13. `run_status.stop_clock`
14. `run_status.exception = exception` if it failed
15. `events.run_completed(node, run_status)` or `events.run_failed(exception, run_status)`
