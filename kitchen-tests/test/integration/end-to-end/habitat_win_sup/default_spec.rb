describe command('C:\habitat\hab.exe sup -h') do
  its(:stdout) { should match(/The Habitat Supervisor/) }
end

describe powershell("(get-service habitat).Status") do
  its(:stdout) { should match(/Running/) }
end

restart_script = <<-EOH
restart-service habitat
EOH

describe powershell(restart_script) do
  its(:exit_status) { should eq(0) }
end

# Removing these two tests temporarily, this needs to be validated and rewritten with the fixture then tested
describe port(9998) do
  it { should be_listening }
end

describe port(9999) do
  it { should be_listening }
end
