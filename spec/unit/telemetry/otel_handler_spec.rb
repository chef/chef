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

require "spec_helper"
require "opentelemetry/sdk"
require "chef/telemetry/otel_handler"

describe Chef::Telemetry::OtelHandler do
  let(:exporter) { OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new }
  let(:provider) do
    OpenTelemetry::SDK::Trace::TracerProvider.new.tap do |p|
      p.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter))
    end
  end
  let(:handler) { described_class.new(tracer_provider: provider) }
  let(:run_status) { instance_double(Chef::RunStatus, run_id: "run-id-123") }
  let(:node) { Chef::Node.new.tap { |n| n.name("client.example.com") } }

  def finished_spans
    exporter.finished_spans
  end

  def span_named(name)
    finished_spans.find { |s| s.name == name }
  end

  it "emits a chef.run root span with ok status for a successful run" do
    handler.run_start("19.3.14", run_status)
    handler.run_completed(node, run_status)

    span = span_named("chef.run")
    expect(span).not_to be_nil
    expect(span.attributes["chef.version"]).to eq("19.3.14")
    expect(span.attributes["chef.run_id"]).to eq("run-id-123")
    expect(span.status.code).to eq(OpenTelemetry::Trace::Status::OK)
  end

  it "marks the chef.run span as errored and records the exception when the run fails" do
    handler.run_start("19.3.14", run_status)
    handler.run_failed(RuntimeError.new("converge blew up"), run_status)

    span = span_named("chef.run")
    expect(span).not_to be_nil
    expect(span.status.code).to eq(OpenTelemetry::Trace::Status::ERROR)
    exception_event = span.events.find { |e| e.name == "exception" }
    expect(exception_event.attributes["exception.message"]).to eq("converge blew up")
  end

  it "emits phase spans as children of the run span" do
    handler.run_start("19.3.14", run_status)
    handler.converge_start(double("run_context"))
    handler.converge_complete
    handler.run_completed(node, run_status)

    run_span = span_named("chef.run")
    converge_span = span_named("chef.converge")
    expect(converge_span).not_to be_nil
    expect(converge_span.parent_span_id).to eq(run_span.span_id)
    expect(converge_span.trace_id).to eq(run_span.trace_id)
  end

  it "emits a span for every paired phase event" do
    phases = {
      "chef.registration" => [[:registration_start, "node", {}], [:registration_completed]],
      "chef.node_load" => [[:node_load_start, "node", {}], [:node_load_completed, node, [], {}]],
      "chef.cookbook_resolution" => [[:cookbook_resolution_start, []], [:cookbook_resolution_complete, double("cookbooks")]],
      "chef.cookbook_clean" => [[:cookbook_clean_start], [:cookbook_clean_complete]],
      "chef.cookbook_sync" => [[:cookbook_sync_start, 5], [:cookbook_sync_complete]],
      "chef.cookbook_gems" => [[:cookbook_gem_start, []], [:cookbook_gem_finished]],
      "chef.cookbook_compilation" => [[:cookbook_compilation_start, double("run_context")], [:cookbook_compilation_complete, double("run_context")]],
      "chef.library_load" => [[:library_load_start, 1], [:library_load_complete]],
      "chef.lwrp_load" => [[:lwrp_load_start, 1], [:lwrp_load_complete]],
      "chef.ohai_plugin_load" => [[:ohai_plugin_load_start, 1], [:ohai_plugin_load_complete]],
      "chef.attribute_load" => [[:attribute_load_start, 1], [:attribute_load_complete]],
      "chef.definition_load" => [[:definition_load_start, 1], [:definition_load_complete]],
      "chef.recipe_load" => [[:recipe_load_start, 1], [:recipe_load_complete]],
      "chef.compliance_load" => [[:compliance_load_start], [:compliance_load_complete]],
      "chef.handlers" => [[:handlers_start, 0], [:handlers_completed]],
    }

    handler.run_start("19.3.14", run_status)
    phases.each_value do |start_call, end_call|
      handler.public_send(*start_call)
      handler.public_send(*end_call)
    end
    handler.run_completed(node, run_status)

    run_span = span_named("chef.run")
    phases.each_key do |span_name|
      span = span_named(span_name)
      expect(span).not_to be_nil, "expected a #{span_name} span"
      expect(span.parent_span_id).to eq(run_span.span_id), "expected #{span_name} to be a child of chef.run"
    end
  end

  it "records the exception and error status when a phase fails" do
    failures = {
      "chef.registration" => [[:registration_start, "node", {}], [:registration_failed, "node", RuntimeError.new("boom"), {}]],
      "chef.node_load" => [[:node_load_start, "node", {}], [:node_load_failed, "node", RuntimeError.new("boom"), {}]],
      "chef.cookbook_resolution" => [[:cookbook_resolution_start, []], [:cookbook_resolution_failed, [], RuntimeError.new("boom")]],
      "chef.cookbook_sync" => [[:cookbook_sync_start, 5], [:cookbook_sync_failed, [], RuntimeError.new("boom")]],
      "chef.cookbook_gems" => [[:cookbook_gem_start, []], [:cookbook_gem_failed, RuntimeError.new("boom")]],
      "chef.converge" => [[:converge_start, double("run_context")], [:converge_failed, RuntimeError.new("boom")]],
    }

    handler.run_start("19.3.14", run_status)
    failures.each_value do |start_call, fail_call|
      handler.public_send(*start_call)
      handler.public_send(*fail_call)
    end
    handler.run_failed(RuntimeError.new("run failed"), run_status)

    failures.each_key do |span_name|
      span = span_named(span_name)
      expect(span.status.code).to eq(OpenTelemetry::Trace::Status::ERROR), "expected #{span_name} to have error status"
      expect(span.events.find { |e| e.name == "exception" }).not_to be_nil, "expected #{span_name} to record its exception"
    end
  end

  it "closes the node_load span when run list expansion fails" do
    handler.run_start("19.3.14", run_status)
    handler.node_load_start("node", {})
    handler.run_list_expand_failed(node, RuntimeError.new("expand failed"))
    handler.run_failed(RuntimeError.new("run failed"), run_status)

    span = span_named("chef.node_load")
    expect(span.status.code).to eq(OpenTelemetry::Trace::Status::ERROR)
  end

  describe "resource spans" do
    let(:resource) do
      Chef::Resource::File.new("/tmp/greeting.txt").tap do |r|
        r.cookbook_name = "greetings"
        r.recipe_name = "default"
      end
    end

    def converge(&block)
      handler.run_start("19.3.14", run_status)
      handler.converge_start(double("run_context"))
      yield
      handler.converge_complete
      handler.run_completed(node, run_status)
    end

    it "emits a resource span with resource attributes under the converge span" do
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_updated(resource, :create)
        handler.resource_completed(resource)
      end

      span = span_named("file[/tmp/greeting.txt]")
      expect(span).not_to be_nil
      expect(span.parent_span_id).to eq(span_named("chef.converge").span_id)
      expect(span.attributes["chef.resource.type"]).to eq("file")
      expect(span.attributes["chef.resource.name"]).to eq("/tmp/greeting.txt")
      expect(span.attributes["chef.resource.action"]).to eq("create")
      expect(span.attributes["chef.resource.cookbook"]).to eq("greetings")
      expect(span.attributes["chef.resource.recipe"]).to eq("default")
      expect(span.attributes["chef.resource.updated"]).to be true
    end

    it "marks up-to-date resources as not updated" do
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_up_to_date(resource, :create)
        handler.resource_completed(resource)
      end

      expect(span_named("file[/tmp/greeting.txt]").attributes["chef.resource.updated"]).to be false
    end

    it "marks skipped resources with the conditional that skipped them" do
      conditional = double("conditional", to_text: "not_if { ::File.exist?('/tmp/greeting.txt') }")
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_skipped(resource, :create, conditional)
        handler.resource_completed(resource)
      end

      span = span_named("file[/tmp/greeting.txt]")
      expect(span.attributes["chef.resource.skipped"]).to be true
      expect(span.attributes["chef.resource.skip_reason"]).to eq("not_if { ::File.exist?('/tmp/greeting.txt') }")
    end

    it "records the exception and error status on a failed resource" do
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_failed(resource, :create, RuntimeError.new("EACCES"))
        handler.resource_completed(resource)
      end

      span = span_named("file[/tmp/greeting.txt]")
      expect(span.status.code).to eq(OpenTelemetry::Trace::Status::ERROR)
      expect(span.events.find { |e| e.name == "exception" }.attributes["exception.message"]).to eq("EACCES")
    end

    it "adds a retry event for retriable failures" do
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_failed_retriable(resource, :create, 2, RuntimeError.new("flaky"))
        handler.resource_completed(resource)
      end

      span = span_named("file[/tmp/greeting.txt]")
      retry_event = span.events.find { |e| e.name == "retry" }
      expect(retry_event).not_to be_nil
      expect(retry_event.attributes["chef.resource.retries_remaining"]).to eq(2)
      expect(span.status.code).not_to eq(OpenTelemetry::Trace::Status::ERROR)
    end

    it "nests sub-resource spans under the outer resource span" do
      inner = Chef::Resource::Execute.new("update-cache")
      converge do
        handler.resource_action_start(resource, :create)
        handler.resource_action_start(inner, :run)
        handler.resource_completed(inner)
        handler.resource_completed(resource)
      end

      outer_span = span_named("file[/tmp/greeting.txt]")
      inner_span = span_named("execute[update-cache]")
      expect(inner_span.parent_span_id).to eq(outer_span.span_id)
    end

    it "records how a notified resource was triggered" do
      notifier = Chef::Resource::Execute.new("update-cache")
      converge do
        handler.resource_action_start(resource, :create, :delayed, notifier)
        handler.resource_completed(resource)
      end

      span = span_named("file[/tmp/greeting.txt]")
      expect(span.attributes["chef.resource.notification_type"]).to eq("delayed")
      expect(span.attributes["chef.resource.notifying_resource"]).to eq("execute[update-cache]")
    end

    it "finishes all open spans when the run fails mid-resource" do
      handler.run_start("19.3.14", run_status)
      handler.converge_start(double("run_context"))
      handler.resource_action_start(resource, :create)
      handler.run_failed(RuntimeError.new("client crashed"), run_status)

      expect(finished_spans.map(&:name)).to contain_exactly("file[/tmp/greeting.txt]", "chef.converge", "chef.run")
      expect(span_named("chef.run").status.code).to eq(OpenTelemetry::Trace::Status::ERROR)
    end
  end

  it "records the node name and environment on the run span once the node is loaded" do
    handler.run_start("19.3.14", run_status)
    handler.node_load_start("client.example.com", {})
    handler.node_load_success(node)
    handler.node_load_completed(node, [], {})
    handler.run_completed(node, run_status)

    span = span_named("chef.run")
    expect(span.attributes["chef.node.name"]).to eq("client.example.com")
    expect(span.attributes["chef.environment"]).to eq("_default")
  end

  it "annotates the current span with ohai completion and deprecations" do
    handler.run_start("19.3.14", run_status)
    handler.ohai_completed(node)
    handler.converge_start(double("run_context"))
    handler.deprecation(double("deprecation", message: "old and busted"), "recipes/default.rb:1")
    handler.converge_complete
    handler.run_completed(node, run_status)

    expect(span_named("chef.run").events.find { |e| e.name == "ohai_completed" }).not_to be_nil
    deprecation_event = span_named("chef.converge").events.find { |e| e.name == "deprecation" }
    expect(deprecation_event.attributes["chef.deprecation.message"]).to eq("old and busted")
  end

  it "force flushes the tracer provider when the run ends" do
    expect(provider).to receive(:force_flush).and_call_original
    handler.run_start("19.3.14", run_status)
    handler.run_completed(node, run_status)
  end

  it "does nothing when the OpenTelemetry SDK is not available" do
    allow_any_instance_of(described_class).to receive(:default_tracer_provider).and_return(nil)
    disabled = described_class.new

    expect do
      disabled.run_start("19.3.14", run_status)
      disabled.converge_start(double("run_context"))
      disabled.resource_action_start(Chef::Resource::File.new("/tmp/x"), :create)
      disabled.resource_completed(Chef::Resource::File.new("/tmp/x"))
      disabled.converge_complete
      disabled.run_completed(node, run_status)
    end.not_to raise_error
  end

  describe ".register!" do
    it "registers exactly one handler even when the config file is evaluated twice" do
      Chef::Config[:event_handlers] = []
      described_class.register!(tracer_provider: provider)
      described_class.register!(tracer_provider: provider)

      expect(Chef::Config[:event_handlers].count { |h| h.is_a?(described_class) }).to eq(1)
    end
  end

  describe "SDK auto-configuration" do
    let(:configurator) { double("configurator") }

    before do
      allow(OpenTelemetry::SDK).to receive(:configure).and_yield(configurator)
      allow(OpenTelemetry).to receive(:tracer_provider).and_return(double("global provider", tracer: double("tracer")))
    end

    it "defaults the service name to chef-client" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OTEL_SERVICE_NAME").and_return(nil)

      expect(configurator).to receive(:service_name=).with("chef-client")
      described_class.new
    end

    it "respects OTEL_SERVICE_NAME when set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OTEL_SERVICE_NAME").and_return("my-service")

      expect(configurator).to receive(:service_name=).with("my-service")
      described_class.new
    end

    it "tags spans with a __tenant resource attribute when tenant: is given" do
      allow(configurator).to receive(:service_name=)

      expect(configurator).to receive(:resource=) do |resource|
        expect(resource.attribute_enumerator.to_h).to eq("__tenant" => "controlplane")
      end
      described_class.new(tenant: "controlplane")
    end

    it "leaves the resource alone when no tenant is given, so OTEL_RESOURCE_ATTRIBUTES applies" do
      allow(configurator).to receive(:service_name=)

      expect(configurator).not_to receive(:resource=)
      described_class.new
    end
  end

  it "disables itself instead of raising into the run when span emission fails" do
    broken_tracer = double("tracer")
    allow(broken_tracer).to receive(:start_span).and_raise("otel exploded")
    allow(provider).to receive(:tracer).and_return(broken_tracer)
    expect(Chef::Log).to receive(:warn).with(/otel exploded/).once

    expect do
      handler.run_start("19.3.14", run_status)
      handler.converge_start(double("run_context"))
      handler.run_completed(node, run_status)
    end.not_to raise_error
  end
end
