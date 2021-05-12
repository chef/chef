describe user("hab") do
  it { should exist }
end

describe file("/bin/hab") do
  it { should exist }
  it { should be_symlink }
end

# This needs to be updated each time Habitat is released so we ensure we're getting the version
# required by this cookbook.
describe command("hab -V") do
  its("stdout") { should match(%r{^hab.*/}) }
  its("exit_status") { should eq 0 }
end

describe file("/hab/svc/nginx/config/nginx.conf") do
  its("content") { should include("worker_processes  2") }
  its("content") { should include("keepalive_timeout  120") }
end

nginxserviceapi = 'curl -v -H "Authorization: Bearer secret" http://localhost:9631/services/nginx/default | jq .cfg'
describe json(command: nginxserviceapi) do
  its(%w{http keepalive_timeout}) { should eq 120 }
  its(%w{http listen port}) { should eq 80 }
  its(["worker_processes"]) { should eq 2 }
end
