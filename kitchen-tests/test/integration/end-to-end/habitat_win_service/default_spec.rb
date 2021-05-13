describe directory('C:\hab\pkgs\skylerto\splunkforwarder') do
  it { should exist }
end

describe directory('C:\hab\pkgs\ncr_devops_platform\sensu-agent-win') do
  it { should exist }
end

describe file('C:\hab\sup\default\specs\splunkforwarder.spec') do
  it { should_not exist }
end

servicecheck = <<-EOH
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer secret")
$uri = "http://localhost:9631/services"
$reply = (Invoke-RestMethod -Headers $headers -uri $uri) | Convertto-Json
$reply
EOH

describe json(command: servicecheck) do
  its(["bldr_url"]) { should eq "https://bldr.habitat.sh/" }
  its(%w{cfg id}) { should eq "hab-sensu-agent" }
  its(%w{cfg backend-urls}) { should eq ["ws://127.0.0.1:8081"] }
  its(["channel"]) { should eq "stable" }
  its(["desired_state"]) { should eq "Down" }
  its(["spec_file"]) { should eq 'C:\\hab/sup\\default\\specs\\sensu-agent-win.spec' }
  its(["topology"]) { should eq "standalone" }
  its(["update_strategy"]) { should eq "rolling" }
end
