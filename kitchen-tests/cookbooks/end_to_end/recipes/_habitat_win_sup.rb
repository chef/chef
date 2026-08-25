# ignore_failure added (VP direction: catalog every pass/fail delta on ARM64
# rather than stop the whole converge on a known issue).
habitat_sup "tester" do
  license "accept"
  bldr_url "https://willem.habitat.sh"
  listen_http "0.0.0.0:9999"
  listen_gossip "0.0.0.0:9998"
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
