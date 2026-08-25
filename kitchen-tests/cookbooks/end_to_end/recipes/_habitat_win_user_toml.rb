# ignore_failure added throughout this recipe (VP direction: catalog every
# pass/fail delta on ARM64 rather than stop the whole converge on a known
# issue -- see chef19-habitat-local-e2e-findings.md, finding #4).
habitat_sup "default" do
  license "accept"
  ignore_failure true
end

ruby_block "wait-for-svc-default-startup" do
  block do
    raise unless system("hab svc status")
  end
  retries 30
  retry_delay 1
  ignore_failure true
end

habitat_user_toml "splunkforwarder" do
  config(
    directories: {
      path: [
        "C:/hab/pkgs/.../*.log",
      ],
    }
  )
  ignore_failure true
end

habitat_service "chef/splunkforwarder" do
  ignore_failure true
end
