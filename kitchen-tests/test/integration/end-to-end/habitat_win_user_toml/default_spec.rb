describe file('C:\habitat\hab.exe') do
  it { should exist }
end

splunkserviceapi = '(Invoke-RestMethod http://localhost:9631/services/splunkforwarder/default).cfg | ConvertTo-Json'
describe json(command: splunkserviceapi) do
  its(%w(directories path)) { should eq ['C:/hab/pkgs/.../*.log'] }
end
