directory "/hab/sup" do
  recursive true
  action :nothing
  retries 30
  retry_delay 1
end

habitat_sup "tester" do
  bldr_url "https://willem.habitat.sh"
  license "accept"
  sup_version "1.6.139"
  launcher_version "13458"
end

ruby_block "wait-for-sup-default-startup" do
  block do
    raise unless system("hab sup status")
  end
  retries 30
  retry_delay 1
end
