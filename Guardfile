# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, :cmd => "bundle exec rspec" do
  watch(%r{^spec/unit/.+_spec\.rb$})
  watch(%r{^lib/chef/(.+)\.rb$})     { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
