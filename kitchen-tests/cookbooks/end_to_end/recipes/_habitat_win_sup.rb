habitat_sup "tester" do
  license "accept"
  bldr_url "https://willem.habitat.sh"
  listen_http "0.0.0.0:9999"
  listen_gossip "0.0.0.0:9998"
end

ruby_block "wait-for-svc-default-startup" do
  block do
    raise unless system("hab svc status")
  end
  retries 30
  retry_delay 1
end
