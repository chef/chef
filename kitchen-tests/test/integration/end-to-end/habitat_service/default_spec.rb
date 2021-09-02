describe directory("/hab/pkgs/core/nginx") do
  it { should exist }
end

describe directory("/hab/pkgs/core/redis") do
  it { should exist }
end

describe file("/hab/sup/default/specs/haproxy.spec") do
  it { should_not exist }
end

describe file("/hab/sup/default/specs/prometheus.spec") do
  it { should exist }
end

grafanaserviceapi = 'curl -v -H "Authorization: Bearer secret" http://localhost:9631/services/grafana/test | jq'
describe json(command: grafanaserviceapi) do
  its(["binding_mode"]) { should eq "relaxed" }
  its(["binds"]) { should eq ["prom:prometheus.default"] }
  its(["bldr_url"]) { should eq "https://bldr-test.habitat.sh/" }
  its(["channel"]) { should eq "bldr-1321420393699319808" }
  its(%w{health_check_interval secs}) { should eq 32 }
  its(%w{pkg ident}) { should eq "core/grafana/6.4.3/20191105024430" }
  its(["service_group"]) { should eq "grafana.test" }
  its(["topology"]) { should eq "standalone" }
  its(["update_condition"]) { should eq "latest" }
  its(["update_strategy"]) { should eq "at-once" }
end

describe directory("/hab/pkgs/core/grafana/6.4.3/20191105024430") do
  it { should exist }
end

describe directory("/hab/pkgs/core/vault/1.1.5") do
  it { should exist }
end

describe file("/hab/sup/default/specs/vault.spec") do
  it { should exist }
  its(:content) { should match(%r{ident = "core/vault/1.1.5"}) }
end

describe file("/hab/sup/default/specs/consul.spec") do
  it { should exist }
  its(:content) { should match(%r{ident = "core/consul"}) }
end

describe file("/hab/sup/default/specs/redis.spec") do
  it { should exist }
  its(:content) { should match(/desired_state = "up"/) }
  its(:content) { should match(/channel = "stable"/) }
end

describe file("/hab/sup/default/specs/memcached.spec") do
  it { should exist }
  its(:content) { should match(/^desired_state = "up"$/) }
end

describe file("/hab/sup/default/specs/sensu.spec") do
  it { should exist }
  its(:content) { should match(/binds = \["rabbitmq:rabbitmq.default", "redis:redis.default"\]/) }
end

describe file("/hab/sup/default/specs/sensu-backend.spec") do
  it { should exist }
  its(:content) { should match(/^desired_state = "up"$/) }
end
