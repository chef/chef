
require "spec_helper"

gem_path = "/opt/chef/embedded/bin/gem"
white_list = %w{addressable chef-config json minitest rake}

describe "gem list" do
  it "should not have non-whitelisted duplicate gems" do
    gems = command("#{gem_path} list").stdout

    duplicate_gems = gems.lines().select { |l| l.include?(",") }.collect { |l| l.split(" ").first }
    puts "Duplicate gems found: #{duplicate_gems}" if duplicate_gems.length > 0

    non_whitelisted_duplicates = duplicate_gems.select { |l| !white_list.include?(l) }
    puts "Non white listed duplicates: #{non_whitelisted_duplicates}" if non_whitelisted_duplicates.length > 0

    (non_whitelisted_duplicates.length).should be == 0
  end
end
