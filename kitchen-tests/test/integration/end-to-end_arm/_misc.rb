# Verifies recipes/_misc.rb: ohai_hint resources write their hint files.
hints_dir = "C:\\chef\\ohai\\hints"

describe file("#{hints_dir}\\hint_at_compile_time.json") do
  it { should exist }
end

describe file("#{hints_dir}\\hint_with_content.json") do
  it { should exist }
  its("content") { should match(/test_content/) }
end

describe file("#{hints_dir}\\hint_without_content.json") do
  it { should exist }
end

describe file("#{hints_dir}\\hint_with_json_in_resource_name.json") do
  it { should exist }
end
