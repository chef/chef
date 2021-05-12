describe user('hab') do
  it { should_not exist }
end

describe command('hab -V') do
  its('stdout') { should match(%r{^hab 1.5.71/}) }
  its('exit_status') { should eq 0 }
end
