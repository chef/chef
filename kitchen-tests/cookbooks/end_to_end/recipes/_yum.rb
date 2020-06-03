bash "disable yum metadata caching" do
  code <<-EOH
    echo http_caching=packages >> /etc/yum.conf
  EOH
  only_if { File.exist?("/etc/yum.conf") && File.readlines("/etc/yum.conf").grep(/http_caching=packages/).empty? }
end

yum_repository "epel" do
  enabled true
  description "Extra Packages for Enterprise Linux #{node["platform_version"].to_i} - $basearch"
  failovermethod "priority"
  gpgkey "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node["platform_version"].to_i}"
  gpgcheck true
  mirrorlist "https://mirrors.fedoraproject.org/metalink?repo=epel-#{node["platform_version"].to_i}&arch=$basearch"
  only_if { rhel? }
end
