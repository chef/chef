# Verifies recipes/_archive.rb: the archive we generated on-node extracts correctly.
describe file("C:\\chef_arm_test\\archive\\sample.zip") do
  it { should exist }
end

describe file("C:\\chef_arm_test\\archive\\extracted\\hello.txt") do
  it { should exist }
  its("content") { should match(/hello from the end_to_end_arm cookbook/) }
end
