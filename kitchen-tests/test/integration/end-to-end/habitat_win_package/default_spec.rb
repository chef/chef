describe file('C:\habitat\hab.exe') do
  it { should exist }
end

# This needs to be updated each time Habitat is released so we ensure we're getting the version
# required by this cookbook.
# TODO: Inspec session seems to not have the updated windows system path when run with 'kitchen test'
# Works fine if you run a converge and then a verify as two separate commands
# For now, hitting hab.exe directly to avoid test failure
describe command('C:\habitat\hab.exe -V') do
  its("stdout") { should match(%r{^hab.*/}) }
  its("exit_status") { should eq 0 }
end

describe directory('C:\hab\pkgs\skylerto\splunkforwarder') do
  it { should exist }
end

# TODO: Same issue as above
describe command('C:\habitat\hab.exe pkg path skylerto/splunkforwarder') do
  its("exit_status") { should eq 0 }
  its("stdout") { should match(/C:\\hab\\pkgs\\skylerto\\splunkforwarder/) }
end
