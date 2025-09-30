return if fedora? && node["platform_version"] >= "33" # ifconfig does not support the new network manager keyfile format
return if ubuntu? && node["platform_version"] >= "20.04"
return if suse?
return if amazon? && node["platform_version"] >= "2023"
return if platform_family?("rhel") && node["platform_version"] >= "10" # ifconfig is deprecated and removed in RHEL 10+

pkg = value_for_platform_family(
  debian: %w{net-tools ifupdown},
  default: "net-tools"
)
package pkg

execute "create virtual interface for testing" do
  command "ifconfig eth0:0 123.123.22.22"
end

ifconfig "33.33.33.80" do
  bootproto "dhcp"
  device "eth0:0"
end

ifconfig "Set eth1 to DHCP" do
  device "eth0:0"
  bootproto "dhcp"
end
