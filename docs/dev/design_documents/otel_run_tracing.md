---
title: OpenTelemetry Run Tracing
---

# OpenTelemetry Run Tracing

`Chef::Telemetry::OtelHandler` emits an OpenTelemetry trace for each chef-client run: a `chef.run` root span, a child span for each run phase (node load, cookbook sync, compilation, converge, ...) and one span per resource action. The trace makes it easy to see where run time is spent and to correlate failed or slow runs with the rest of your distributed tracing in a backend such as Tempo or Jaeger.

Like the Data Collector, the handler is a `Chef::EventDispatch::Base` subscriber. The event stream is the only interface that delivers live, paired start/complete events for every phase and resource action, which map one-to-one onto span open/close with real wall-clock timestamps. Report/exception handlers only run at the end of the run (and not at all if the run crashes hard), and output formatters are operator-selected for human display, so neither is a suitable hook for telemetry.

## Enabling tracing

Add the following to `client.rb` (or `solo.rb`):

```ruby
require "chef/telemetry/otel_handler"
Chef::Telemetry::OtelHandler.register!
```

`register!` is idempotent: applications such as chef-solo evaluate the config file more than once, and only one handler is ever registered.

The exporter and endpoint are configured through the standard `OTEL_*` environment variables, for example:

```shell
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

The handler soft-requires the `opentelemetry-sdk` gem (plus `opentelemetry-exporter-otlp` for the default OTLP exporter). If the gems are not installed, the handler logs a warning and does nothing. If span emission ever raises mid-run, the handler disables itself for the rest of the run rather than letting the error propagate — tracing can never break a converge.

If something else in the process has already configured the global OpenTelemetry SDK before the handler loads, that configuration (including its resource attributes) is used as-is.

## Service name and tenant

The service name defaults to `chef-client` and can be overridden with `OTEL_SERVICE_NAME`.

Spans can be tagged with a `__tenant` resource attribute (used by Tempo multi-tenancy for search and tail-sampling routing) either through the standard env var:

```shell
OTEL_RESOURCE_ATTRIBUTES=__tenant=controlplane
```

or explicitly at registration, which takes precedence over the env var:

```ruby
Chef::Telemetry::OtelHandler.register!(tenant: "controlplane")
```

## Span structure

```text
chef.run                          chef.version, chef.run_id, chef.node.name, chef.environment
├─ chef.registration
├─ chef.node_load
├─ chef.cookbook_resolution
├─ chef.cookbook_clean
├─ chef.cookbook_sync
├─ chef.cookbook_gems
├─ chef.cookbook_compilation
│  ├─ chef.library_load
│  ├─ chef.ohai_plugin_load
│  ├─ chef.compliance_load
│  ├─ chef.attribute_load
│  ├─ chef.lwrp_load
│  ├─ chef.definition_load
│  └─ chef.recipe_load
├─ chef.converge
│  └─ one span per resource action, named e.g. file[/etc/motd]
└─ chef.handlers
```

Each resource span carries `chef.resource.type`, `chef.resource.name`, `chef.resource.action`, `chef.resource.cookbook` and `chef.resource.recipe`, plus outcome detail:

* `chef.resource.updated` — `true`/`false` for converged resources
* `chef.resource.skipped` and `chef.resource.skip_reason` — for resources skipped by a guard or `action :nothing`
* `chef.resource.notification_type` and `chef.resource.notifying_resource` — when the action ran due to a notification
* failed resources record the exception on the span and set error status; retries appear as `retry` span events

The `chef.run` root span ends with OK status on success, or error status (with the exception recorded) when the run fails. Deprecation warnings are attached as `deprecation` span events. An immediately-notified resource's span is a sibling of its notifier under `chef.converge` (the notifier's span closes before the notification fires); the relationship is preserved by the `chef.resource.notifying_resource` attribute.

## Testing locally

The SDK's console exporter prints spans to stdout, which is handy for verifying output without a collector:

```shell
OTEL_TRACES_EXPORTER=console chef-solo -c solo.rb -o 'recipe[my_cookbook]'
```
