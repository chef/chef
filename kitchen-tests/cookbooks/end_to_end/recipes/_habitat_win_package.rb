# ignore_failure added (VP direction: catalog every pass/fail delta on
# ARM64 rather than stop the whole converge on a known issue).
habitat_install "default" do
  license "accept"
  ignore_failure true
end

habitat_package "chef/splunkforwarder" do
  version "7.0.3/20250714155325"
  ignore_failure true
end
