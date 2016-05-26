#describe port(80) do
#  it { should be_listening }
#  its('processes') {should include 'http'}
#end
#
#describe command("curl http://localhost/index.html") do
#  its("stdout") { should match /Hello, World!/ }
#end

case os[:family]
when "debian", "ubuntu"
  ssh_package = "openssh-client"
  ssh_service = "ssh"
  ntp_service = "ntp"
when "centos", "redhat", "fedora"
  ssh_package = "openssh-clients"
  ssh_service = "sshd"
  ntp_service = "ntpd"
else
  raise "i don't know the family #{os[:family]}"
end

describe package("nscd") do
  it { should be_installed }
end

describe service("nscd") do
  # broken?
  #  it { should be_enabled }
  it { should be_installed }
  it { should be_running }
end

describe package(ssh_package) do
  it { should be_installed }
end

describe service(ssh_service) do
  it { should be_enabled }
  it { should be_installed }
  it { should be_running }
end

describe sshd_config do
  its("Protocol") { should cmp 2 }
  its("GssapiAuthentication") { should cmp "no" }
  its("UseDns") { should cmp "no" }
end

describe ssh_config do
  its("StrictHostKeyChecking") { should cmp "no" }
  its("GssapiAuthentication") { should cmp "no" }
end

describe package("ntp") do
  it { should be_installed }
end

describe service(ntp_service) do
  # broken?
  #  it { should be_enabled }
  it { should be_installed }
  it { should be_running }
end

describe service("chef-client") do
  it { should be_enabled }
  it { should be_installed }
  it { should be_running }
end

describe file("/etc/resolv.conf") do
  its("content") { should match /search\s+chef.io/ }
  its("content") { should match /nameserver\s+8.8.8.8/ }
  its("content") { should match /nameserver\s+8.8.4.4/ }
end

describe package("gcc") do
  it { should be_installed }
end

describe package("flex") do
  it { should be_installed }
end

describe package("bison") do
  it { should be_installed }
end

describe package("autoconf") do
  it { should be_installed }
end

%w{lsof tcpdump strace zsh dmidecode ltrace bc curl wget telnet subversion git traceroute htop tmux s3cmd sysbench }.each do |pkg|
  describe package pkg do
    it { should be_installed }
  end
end

describe etc_group.where(group_name: "sysadmin") do
  its("users") { should include "adam" }
  its("gids") { should eq [2300] }
end

describe passwd.users("adam") do
  its("uids") { should eq ["666"] }
end

describe ntp_conf do
  its("server") { should_not eq nil }
end

# busted inside of docker containers?
describe port(22) do
  it { should be_listening }
  its("protocols") { should include "tcp" }
  its("processes") { should eq ["sshd"] }
end
