habitat_install "default" do
  license "accept"
end

habitat_package "chef/splunkforwarder" do
  version "7.0.3/20250714155325"
end
