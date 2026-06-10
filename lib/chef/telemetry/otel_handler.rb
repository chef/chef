#
# Author:: Jason Cook (<jasonc@simpleideas.org>)
# Copyright:: Copyright (c) Jason Cook
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../event_dispatch/base"
require_relative "../log"
require_relative "../config"

class Chef
  module Telemetry
    # Emits an OpenTelemetry trace for the chef-client run: a root span for
    # the run, child spans for each phase (node load, cookbook sync,
    # compilation, converge, ...) and one span per resource action.
    #
    # Enable it from client.rb (or solo.rb):
    #
    #   require "chef/telemetry/otel_handler"
    #   Chef::Telemetry::OtelHandler.register!
    #
    # Exporter and endpoint are configured through the standard OTEL_*
    # environment variables. Requires the opentelemetry-sdk gem (and
    # opentelemetry-exporter-otlp for the default exporter); if they are not
    # installed the handler logs a warning and does nothing.
    #
    # Spans can be tagged with a __tenant resource attribute (used by Tempo
    # multi-tenancy for search and tail-sampling routing) either through the
    # standard env var:
    #
    #   OTEL_RESOURCE_ATTRIBUTES=__tenant=controlplane
    #
    # or explicitly, which takes precedence over the env var:
    #
    #   Chef::Telemetry::OtelHandler.register!(tenant: "controlplane")
    class OtelHandler < Chef::EventDispatch::Base
      # Adds the handler to Chef::Config[:event_handlers]. Idempotent, because
      # some applications (chef-solo) evaluate the config file more than once
      # and a second handler would emit every span twice.
      def self.register!(**opts)
        return if Chef::Config[:event_handlers].any? { |handler| handler.is_a?(self) }

        Chef::Config[:event_handlers] << new(**opts)
      end

      def initialize(tracer_provider: nil, tenant: nil)
        @stack = []
        @tracer_provider = tracer_provider || default_tracer_provider(tenant)
        @tracer = @tracer_provider&.tracer("chef", Chef::VERSION)
      end

      def run_start(version, run_status)
        start_span("chef.run", {
          "chef.version" => version.to_s,
          "chef.run_id" => run_status.run_id.to_s,
        })
      end

      def run_completed(node, run_status)
        end_span("chef.run", ok: true)
        @tracer_provider&.force_flush
      end

      def run_failed(exception, run_status)
        end_span("chef.run", error: exception)
        @tracer_provider&.force_flush
      end

      def node_load_success(node)
        root_span&.set_attribute("chef.node.name", node.name.to_s)
        root_span&.set_attribute("chef.environment", node.chef_environment.to_s)
      end

      def ohai_completed(node)
        current_span&.add_event("ohai_completed")
      end

      def deprecation(message, location = nil)
        text = message.respond_to?(:message) ? message.message.to_s : message.to_s
        attributes = { "chef.deprecation.message" => text }
        attributes["chef.deprecation.location"] = location.to_s if location
        current_span&.add_event("deprecation", attributes: attributes)
      end

      # Paired phase events: the start event opens a span, the end event
      # closes it. Event arguments are not recorded on phase spans.
      {
        "chef.registration" => %i{registration_start registration_completed},
        "chef.node_load" => %i{node_load_start node_load_completed},
        "chef.cookbook_resolution" => %i{cookbook_resolution_start cookbook_resolution_complete},
        "chef.cookbook_clean" => %i{cookbook_clean_start cookbook_clean_complete},
        "chef.cookbook_sync" => %i{cookbook_sync_start cookbook_sync_complete},
        "chef.cookbook_gems" => %i{cookbook_gem_start cookbook_gem_finished},
        "chef.cookbook_compilation" => %i{cookbook_compilation_start cookbook_compilation_complete},
        "chef.library_load" => %i{library_load_start library_load_complete},
        "chef.lwrp_load" => %i{lwrp_load_start lwrp_load_complete},
        "chef.ohai_plugin_load" => %i{ohai_plugin_load_start ohai_plugin_load_complete},
        "chef.attribute_load" => %i{attribute_load_start attribute_load_complete},
        "chef.definition_load" => %i{definition_load_start definition_load_complete},
        "chef.recipe_load" => %i{recipe_load_start recipe_load_complete},
        "chef.compliance_load" => %i{compliance_load_start compliance_load_complete},
        "chef.converge" => %i{converge_start converge_complete},
        "chef.handlers" => %i{handlers_start handlers_completed},
      }.each do |span_name, (start_event, end_event)|
        define_method(start_event) { |*_args| start_span(span_name) }
        define_method(end_event) { |*_args| end_span(span_name) }
      end

      # Failure events close their phase span with error status; the value is
      # the position of the exception in the event's arguments.
      {
        registration_failed: ["chef.registration", 1],
        node_load_failed: ["chef.node_load", 1],
        run_list_expand_failed: ["chef.node_load", 1],
        cookbook_resolution_failed: ["chef.cookbook_resolution", 1],
        cookbook_sync_failed: ["chef.cookbook_sync", 1],
        cookbook_gem_failed: ["chef.cookbook_gems", 0],
        converge_failed: ["chef.converge", 0],
      }.each do |event, (span_name, exception_index)|
        define_method(event) { |*args| end_span(span_name, error: args[exception_index]) }
      end

      def resource_action_start(resource, action, notification_type = nil, notifier = nil)
        attributes = {
          "chef.resource.type" => resource.resource_name.to_s,
          "chef.resource.name" => resource.name.to_s,
          "chef.resource.action" => action.to_s,
        }
        attributes["chef.resource.cookbook"] = resource.cookbook_name.to_s if resource.cookbook_name
        attributes["chef.resource.recipe"] = resource.recipe_name.to_s if resource.recipe_name
        attributes["chef.resource.notification_type"] = notification_type.to_s if notification_type
        attributes["chef.resource.notifying_resource"] = notifier.to_s if notifier
        start_span(resource.to_s, attributes)
      end

      def resource_updated(resource, action)
        current_span&.set_attribute("chef.resource.updated", true)
      end

      def resource_up_to_date(resource, action)
        current_span&.set_attribute("chef.resource.updated", false)
      end

      def resource_skipped(resource, action, conditional)
        span = current_span
        return unless span

        span.set_attribute("chef.resource.skipped", true)
        span.set_attribute("chef.resource.skip_reason", conditional.to_text)
      end

      def resource_failed(resource, action, exception)
        span = current_span
        return unless span

        span.record_exception(exception)
        span.status = OpenTelemetry::Trace::Status.error(exception.message)
      end

      def resource_failed_retriable(resource, action, retry_count, exception)
        current_span&.add_event("retry", attributes: {
          "chef.resource.retries_remaining" => retry_count,
          "exception.message" => exception.message,
        })
      end

      def resource_completed(resource)
        end_span(resource.to_s)
      end

      private

      def current_span
        @stack.last && @stack.last[1]
      end

      def root_span
        @stack.first && @stack.first[1]
      end

      # Opens a span as a child of whatever span is currently innermost and
      # pushes it on the stack. Events arrive synchronously on one thread, so
      # the stack mirrors the nesting of the run.
      def start_span(name, attributes = {})
        return unless @tracer

        parent = @stack.last
        context = parent ? OpenTelemetry::Trace.context_with_span(parent[1]) : OpenTelemetry::Context.current
        @stack << [name, @tracer.start_span(name, with_parent: context, attributes: attributes)]
      end

      # Finishes the named span. If intervening spans were left open (an end
      # event that never fired), they are finished too; if the named span is
      # not open at all, this is a no-op.
      def end_span(name, error: nil, ok: false)
        return unless @stack.any? { |n, _| n == name }

        loop do
          span_name, span = @stack.pop
          if span_name == name
            if error
              span.record_exception(error)
              span.status = OpenTelemetry::Trace::Status.error(error.message)
            elsif ok
              span.status = OpenTelemetry::Trace::Status.ok
            end
          end
          span.finish
          break if span_name == name
        end
      end

      def default_tracer_provider(tenant = nil)
        require "opentelemetry/sdk"
        unless OpenTelemetry.tracer_provider.is_a?(OpenTelemetry::SDK::Trace::TracerProvider)
          OpenTelemetry::SDK.configure do |config|
            config.service_name = ENV["OTEL_SERVICE_NAME"] || "chef-client"
            # Configurator#resource= merges into the default resource, which
            # already carries OTEL_RESOURCE_ATTRIBUTES, so an explicit tenant
            # wins over the env var.
            config.resource = OpenTelemetry::SDK::Resources::Resource.create("__tenant" => tenant.to_s) if tenant
          end
        end
        OpenTelemetry.tracer_provider
      rescue LoadError
        Chef::Log.warn("opentelemetry-sdk is not installed; OTel tracing of the chef run is disabled")
        nil
      end

      # Tracing must never break the chef run: if any event method raises,
      # log it and ignore all further events instead of letting the error
      # propagate into the event dispatcher. Defined last so it wraps every
      # event method above.
      crash_guard = Module.new do
        OtelHandler.public_instance_methods(false).each do |event|
          define_method(event) do |*args|
            return if @broken

            begin
              super(*args)
            rescue Exception => e # rubocop:disable Lint/RescueException
              @broken = true
              Chef::Log.warn("OTel tracing handler failed (#{e.class}: #{e.message}); tracing disabled for the rest of this run")
            end
          end
        end
      end
      prepend crash_guard
    end
  end
end
