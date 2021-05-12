describe command("/bin/hab sup -h") do
  its(:stdout) { should match(/The Habitat Supervisor/) }
end

svc_manager = if command("systemctl --help").exit_status == 0
                "systemd"
              elsif command("initctl --help").exit_status == 0
                "upstart"
              else
                "sysv"
              end

describe send("#{svc_manager}_service", "hab-sup") do
  it { should be_running }
end

cmd = case svc_manager
      when "systemd"
        "systemctl restart hab-sup"
      when "upstart"
        "initctl restart hab-sup"
      when "sysv"
        "/etc/init.d/hab-sup restart"
      end

describe command(cmd) do
  its(:exit_status) { should eq(0) }
end

describe send("#{svc_manager}_service", "hab-sup") do
  it { should be_running }
end

# Validate HAB_AUTH_TOKEN
case svc_manager
when "systemd"
  describe file("/etc/systemd/system/hab-sup.service") do
    its("content") { should_not match("Environment = HAB_AUTH_TOKEN=test") }
    its("content") { should_not match("Environment = HAB_SUP_GATEWAY_AUTH_TOKEN=secret") }
    its("content") { should_not match("LimitNOFILE = 65536") }
  end
when "upstart"
  describe file("/etc/init/hab-sup.conf") do
    its("content") { should_not match("env HAB_AUTH_TOKEN=test") }
    its("content") { should_not match("env HAB_SUP_GATEWAY_AUTH_TOKEN=secret") }
  end
when "sysv"
  describe file("/etc/init.d/hab-sup") do
    its("content") { should_not match("export HAB_AUTH_TOKEN=test") }
    its("content") { should_not match("export HAB_SUP_GATEWAY_AUTH_TOKEN=secret") }
  end
end

describe port(7999) do
  it { should be_listening }
end

describe port(7998) do
  it { should be_listening }
end

describe file("/hab/sup/default/config/sup.toml") do
  it { should exist }
  its("content") { should match(/peer.*127.0.0.2:9632.*127.0.0.3:9632/) }
end
