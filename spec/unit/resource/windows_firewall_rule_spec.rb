# Author:: Tor Magnus Rakvåg (tor.magnus@outlook.com)
# Copyright:: 2018, Intility AS
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Resource::WindowsFirewallRule do
  let(:resource) { Chef::Resource::WindowsFirewallRule.new("rule") }
  let(:provider) { resource.provider_for_action(:create) }

  it "has a resource name of :windows_firewall_rule" do
    expect(resource.resource_name).to eql(:windows_firewall_rule)
  end

  it "the name_property is 'rule_name'" do
    expect(resource.rule_name).to eql("rule")
  end

  it "the default action is :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "the rule_name property accepts strings" do
    resource.rule_name("rule2")
    expect(resource.rule_name).to eql("rule2")
  end

  it "the description property accepts strings" do
    resource.description("firewall rule")
    expect(resource.description).to eql("firewall rule")
  end

  it "the group property accepts strings" do
    resource.group("New group")
    expect(resource.group).to eql("New group")
  end

  it "the local_address property accepts strings" do
    resource.local_address("192.168.1.1")
    expect(resource.local_address).to eql("192.168.1.1")
  end

  it "the local_port property accepts integers" do
    resource.local_port(8080)
    expect(resource.local_port).to eql(["8080"])
  end

  it "the local_port property accepts strings" do
    resource.local_port("8080")
    expect(resource.local_port).to eql(["8080"])
  end

  it "the local_port property accepts comma separated lists without spaces" do
    resource.local_port("8080,8081")
    expect(resource.local_port).to eql(%w{8080 8081})
  end

  it "the local_port property accepts comma separated lists with spaces" do
    resource.local_port("8080, 8081")
    expect(resource.local_port).to eql(%w{8080 8081})
  end

  it "the local_port property accepts arrays and coerces to a sorta array of strings" do
    resource.local_port([8081, 8080])
    expect(resource.local_port).to eql(%w{8080 8081})
  end

  it "the remote_address property accepts strings" do
    resource.remote_address("8.8.4.4")
    expect(resource.remote_address).to eql(["8.8.4.4"])
  end

  it "the remote_address property accepts comma separated lists" do
    resource.remote_address(["10.17.3.101", "172.7.7.53"])
    expect(resource.remote_address).to eql(%w{10.17.3.101 172.7.7.53})
  end

  it "the remote_port property accepts strings" do
    resource.remote_port("8081")
    expect(resource.remote_port).to eql(["8081"])
  end

  it "the remote_port property accepts integers" do
    resource.remote_port(8081)
    expect(resource.remote_port).to eql(["8081"])
  end

  it "the remote_port property accepts comma separated lists without spaces" do
    resource.remote_port("8080,8081")
    expect(resource.remote_port).to eql(%w{8080 8081})
  end

  it "the remote_port property accepts comma separated lists with spaces" do
    resource.remote_port("8080, 8081")
    expect(resource.remote_port).to eql(%w{8080 8081})
  end

  it "the remote_port property accepts arrays and coerces to a sorta array of strings" do
    resource.remote_port([8081, 8080])
    expect(resource.remote_port).to eql(%w{8080 8081})
  end

  it "the direction property accepts :inbound and :outbound" do
    resource.direction(:inbound)
    expect(resource.direction).to eql(:inbound)
    resource.direction(:outbound)
    expect(resource.direction).to eql(:outbound)
  end

  it "the direction property coerces strings to symbols" do
    resource.direction("Inbound")
    expect(resource.direction).to eql(:inbound)
  end

  it "the protocol property accepts strings" do
    resource.protocol("TCP")
    expect(resource.protocol).to eql("TCP")
  end

  it "the icmp_type property accepts strings" do
    resource.icmp_type("Any")
    expect(resource.icmp_type).to eql("Any")
  end

  it "the icmp_type property accepts integers" do
    resource.icmp_type(8)
    expect(resource.icmp_type).to eql(8)
  end

  it "the firewall_action property accepts :allow, :block and :notconfigured" do
    resource.firewall_action(:allow)
    expect(resource.firewall_action).to eql(:allow)
    resource.firewall_action(:block)
    expect(resource.firewall_action).to eql(:block)
    resource.firewall_action(:notconfigured)
    expect(resource.firewall_action).to eql(:notconfigured)
  end

  it "the firewall_action property coerces strings to symbols" do
    resource.firewall_action("Allow")
    expect(resource.firewall_action).to eql(:allow)
  end

  it "the profile property accepts :public, :private, :domain, :any and :notapplicable" do
    resource.profile(:public)
    expect(resource.profile).to eql([:public])
    resource.profile(:private)
    expect(resource.profile).to eql([:private])
    resource.profile(:domain)
    expect(resource.profile).to eql([:domain])
    resource.profile(:any)
    expect(resource.profile).to eql([:any])
    resource.profile(:notapplicable)
    expect(resource.profile).to eql([:notapplicable])
  end

  it "the profile property raises on any unknown values" do
    expect { resource.profile(:other) }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.profile(%i{public other}) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "the profile property coerces strings to symbols" do
    resource.profile("Public")
    expect(resource.profile).to eql([:public])
    resource.profile([:private, "Public"])
    expect(resource.profile).to eql(%i{private public})
  end

  it "the profile property supports multiple profiles" do
    resource.profile(%w{Private Public})
    expect(resource.profile).to eql(%i{private public})
  end

  it "the program property accepts strings" do
    resource.program("C:/Test/test.exe")
    expect(resource.program).to eql("C:/Test/test.exe")
  end

  it "the service property accepts strings" do
    resource.service("Spooler")
    expect(resource.service).to eql("Spooler")
  end

  it "the interface_type property accepts :any, :wireless, :wired and :remoteaccess" do
    resource.interface_type(:any)
    expect(resource.interface_type).to eql(:any)
    resource.interface_type(:wireless)
    expect(resource.interface_type).to eql(:wireless)
    resource.interface_type(:wired)
    expect(resource.interface_type).to eql(:wired)
    resource.interface_type(:remoteaccess)
    expect(resource.interface_type).to eql(:remoteaccess)
  end

  it "the interface_type property coerces strings to symbols" do
    resource.interface_type("Any")
    expect(resource.interface_type).to eql(:any)
  end

  it "the enabled property accepts true and false" do
    resource.enabled(true)
    expect(resource.enabled).to eql(true)
    resource.enabled(false)
    expect(resource.enabled).to eql(false)
  end

  it "aliases :localip to :local_address" do
    resource.localip("192.168.30.30")
    expect(resource.local_address).to eql("192.168.30.30")
  end

  it "aliases :remoteip to :remote_address" do
    resource.remoteip(["8.8.8.8"])
    expect(resource.remote_address).to eql(["8.8.8.8"])
  end

  it "aliases :localport to :local_port" do
    resource.localport("80")
    expect(resource.local_port).to eql(["80"])
  end

  it "aliases :remoteport to :remote_port" do
    resource.remoteport("8080")
    expect(resource.remote_port).to eql(["8080"])
  end

  it "aliases :interfacetype to :interface_type" do
    resource.interfacetype(:any)
    expect(resource.interface_type).to eql(:any)
  end

  describe "#firewall_command" do
    before do
      resource.rule_name("test_rule")
    end

    context "#new" do
      it "build a minimal command" do
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets a description" do
        resource.description("New description")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Description 'New description' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets a displayname" do
        resource.displayname("New displayname")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'New displayname' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets a group" do
        resource.group("New groupname")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Group 'New groupname' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalAddress" do
        resource.local_address("127.0.0.1")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -LocalAddress '127.0.0.1' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalPort" do
        resource.local_port("80")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -LocalPort '80' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalPort with int" do
        resource.local_port(80)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -LocalPort '80' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets multiple LocalPorts" do
        resource.local_port(%w{80 RPC})
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -LocalPort '80', 'RPC' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemoteAddress" do
        resource.remote_address(["8.8.8.8"])
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -RemoteAddress '8.8.8.8' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemotePort" do
        resource.remote_port("443")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -RemotePort '443' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemotePort with int" do
        resource.remote_port(443)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -RemotePort '443' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets multiple RemotePorts" do
        resource.remote_port(%w{443 445})
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -RemotePort '443', '445' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Direction" do
        resource.direction(:outbound)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'outbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Protocol" do
        resource.protocol("UDP")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'UDP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets ICMP Protocol with type 8" do
        resource.protocol("ICMPv6")
        resource.icmp_type(8)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'ICMPv6' -IcmpType '8' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Action" do
        resource.firewall_action(:block)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'block' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Profile" do
        resource.profile(:private)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'private' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets multiple Profiles (must be comma-plus-space delimited for PowerShell to treat as an array)" do
        resource.profile(%i{private public})
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'private', 'public' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Program" do
        resource.program("C:/calc.exe")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -Program 'C:/calc.exe' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Service" do
        resource.service("Spooler")
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -Service 'Spooler' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets InterfaceType" do
        resource.interface_type(:wired)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'wired' -Enabled 'true'")
      end

      it "sets Enabled" do
        resource.enabled(false)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule' -DisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'false'")
      end

      it "sets all properties UDP" do
        resource.rule_name("test_rule_the_second")
        resource.displayname("some cool display name")
        resource.description("some other rule")
        resource.group("new group")
        resource.local_address("192.168.40.40")
        resource.local_port("80")
        resource.remote_address(["8.8.4.4"])
        resource.remote_port("8081")
        resource.direction(:outbound)
        resource.protocol("UDP")
        resource.icmp_type("Any")
        resource.firewall_action(:notconfigured)
        resource.profile(:domain)
        resource.program('%WINDIR%\System32\lsass.exe')
        resource.service("SomeService")
        resource.interface_type(:remoteaccess)
        resource.enabled(false)
        expect(provider.firewall_command("New")).to eql("New-NetFirewallRule -Name 'test_rule_the_second' -DisplayName 'some cool display name' -Group 'new group' -Description 'some other rule' -LocalAddress '192.168.40.40' -LocalPort '80' -RemoteAddress '8.8.4.4' -RemotePort '8081' -Direction 'outbound' -Protocol 'UDP' -IcmpType 'Any' -Action 'notconfigured' -Profile 'domain' -Program '%WINDIR%\\System32\\lsass.exe' -Service 'SomeService' -InterfaceType 'remoteaccess' -Enabled 'false'")
      end
    end

    context "#set" do
      it "build a minimal command" do
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets a displayname" do
        resource.displayname("New displayname")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'New displayname' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets a description" do
        resource.description("New description")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Description 'New description' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalAddress" do
        resource.local_address("127.0.0.1")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -LocalAddress '127.0.0.1' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalPort" do
        resource.local_port("80")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -LocalPort '80' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets LocalPort with int" do
        resource.local_port(80)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -LocalPort '80' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets multiple LocalPorts (must be comma-plus-space delimited for PowerShell to treat as an array)" do
        resource.local_port(%w{80 8080})
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -LocalPort '80', '8080' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemoteAddress" do
        resource.remote_address(["8.8.8.8"])
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -RemoteAddress '8.8.8.8' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemotePort" do
        resource.remote_port("443")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -RemotePort '443' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets RemotePort with int" do
        resource.remote_port(443)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -RemotePort '443' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets multiple RemotePorts (must be comma-plus-space delimited for PowerShell to treat as an array)" do
        resource.remote_port(%w{443 445})
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -RemotePort '443', '445' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Direction" do
        resource.direction(:outbound)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'outbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Protocol" do
        resource.protocol("UDP")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'UDP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets ICMP Protocol with type 8" do
        resource.protocol("ICMPv6")
        resource.icmp_type(8)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'ICMPv6' -IcmpType '8' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Action" do
        resource.firewall_action(:block)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'block' -Profile 'any' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Profile" do
        resource.profile(:private)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'private' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Program" do
        resource.program("C:/calc.exe")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -Program 'C:/calc.exe' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets Service" do
        resource.service("Spooler")
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -Service 'Spooler' -InterfaceType 'any' -Enabled 'true'")
      end

      it "sets InterfaceType" do
        resource.interface_type(:wired)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'wired' -Enabled 'true'")
      end

      it "sets Enabled" do
        resource.enabled(false)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule' -NewDisplayName 'test_rule' -Direction 'inbound' -Protocol 'TCP' -IcmpType 'Any' -Action 'allow' -Profile 'any' -InterfaceType 'any' -Enabled 'false'")
      end

      it "sets all properties" do
        resource.rule_name("test_rule_the_second")
        resource.description("some other rule")
        resource.displayname("some cool display name")
        resource.local_address("192.168.40.40")
        resource.local_port("80")
        resource.remote_address(["8.8.4.4"])
        resource.remote_port("8081")
        resource.direction(:outbound)
        resource.protocol("UDP")
        resource.icmp_type("Any")
        resource.firewall_action(:notconfigured)
        resource.profile(:domain)
        resource.program('%WINDIR%\System32\lsass.exe')
        resource.service("SomeService")
        resource.interface_type(:remoteaccess)
        resource.enabled(false)
        expect(provider.firewall_command("Set")).to eql("Set-NetFirewallRule -Name 'test_rule_the_second' -NewDisplayName 'some cool display name' -Description 'some other rule' -LocalAddress '192.168.40.40' -LocalPort '80' -RemoteAddress '8.8.4.4' -RemotePort '8081' -Direction 'outbound' -Protocol 'UDP' -IcmpType 'Any' -Action 'notconfigured' -Profile 'domain' -Program '%WINDIR%\\System32\\lsass.exe' -Service 'SomeService' -InterfaceType 'remoteaccess' -Enabled 'false'")
      end
    end
  end
end
