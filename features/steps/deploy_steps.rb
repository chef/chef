require 'chef/shell_out'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

# Given /^I have a clone of typo in the data\/tmp dir$/ do
#   cmd = "git clone #{datadir}/typo.bundle #{tmpdir}/gitrepo/typo"
#   `#{cmd}`
# end
def gem_installed?(gem_name, version)
  cmd = "gem list -i #{gem_name} -v #{version}"
  `#{cmd}`=~ /true/ ? true : false
end


Given /^I have a clone of the rails app in the data\/tmp dir$/ do
  cmd = "git clone #{datadir}/myapp.bundle #{tmpdir}/gitrepo/myapp"
  `#{cmd}`
end

Given /^that I have '(.*)' '(.*)' installed$/ do |gem_name, version|
  unless gem_installed?(gem_name, version)
    pending "This Cucumber feature will not execute, as #{gem_name} #{version} is not installed."
  end
end

Given /^a test git repo in the temp directory$/ do
  test_git_repo_tarball_filename = "#{datadir}/test_git_repo.tar.gz"
  cmd = Chef::ShellOut.new("tar xzvf #{test_git_repo_tarball_filename} -C #{tmpdir}")
  cmd.run_command.exitstatus.should == 0
end

When /^I remove the remote repository named '(.+)' from '(.+)'$/ do |remote_name, repository_dir|
  shell_out!("git remote rm #{remote_name}", Hash[:cwd => File.join(tmpdir, repository_dir)])
end

Then /^I should hear about it$/ do
  puts "==deploy:"
  puts `ls #{tmpdir}/deploy/`
  puts "==Releases:"
  puts `ls #{tmpdir}/deploy/releases/`
  puts "==Releases/*/"
  puts `ls #{tmpdir}/deploy/releases/*/`
  puts "==Releases/*/db"
  puts `ls #{tmpdir}/deploy/releases/*/db/`
  puts "==Releases/*/config/"
  puts `ls #{tmpdir}/deploy/releases/*/config/`
  puts "==current:"
  puts `ls #{tmpdir}/deploy/current/`
  puts "==current/db:"
  puts `ls #{tmpdir}/deploy/current/db/`
  puts "==current/deploy:"
  puts `ls #{tmpdir}/deploy/current/deploy/`
  puts "==current/app:"
  puts `ls #{tmpdir}/deploy/current/app/`
  puts "==current/config:"
  puts `ls #{tmpdir}/deploy/current/config/`
  puts "==shared/config/app_config.yml"
  puts `ls #{tmpdir}/deploy/shared/config/`
end

Then /^there should be '(.*)' releases?$/ do |n|
  numnums = {"one" => 1, "two" => 2, "three" => 3}
  n = numnums.has_key?(n) ? numnums[n] : n.to_i
  @releases = Dir.glob(tmpdir + "/deploy/releases/*")
  @releases.size.should eql(n)
end

Then /^a callback named <callback_file> should exist$/ do |callback_files|
  callback_files.raw.each do |file|
    want_file = "deploy/current/deploy/#{file.first}"
    Then "a file named '#{want_file}' should exist"
  end
end

Then /^the callback named <callback> should have run$/ do |callback_files|
  callback_files.raw.each do |file|
    hook_name = file.first.gsub(/\.rb$/, "")
    evidence_file = "deploy/current/app/" + hook_name
    expected_contents = {"hook_name" => hook_name, "env" => "production"}
    actual_contents = Chef::JSONCompat.from_json(IO.read(File.join(tmpdir, evidence_file)))
    expected_contents.should == actual_contents
  end
end

Then /^the second chef run should have skipped deployment$/ do
  expected_deploy = "#{tmpdir}/deploy/releases/62c9979f6694612d9659259f8a68d71048ae9a5b"
  Then "'stdout' should not have 'INFO: Already deployed app at #{expected_deploy}.  Rolling back to it - use action :force_deploy to re-checkout this revision.'"
end

Then /^a remote repository named '(.*)' should exist in '(.*)'$/ do |remote_name, repository_dir|
  remotes = shell_out!('git remote', Hash[:cwd => File.join(tmpdir, repository_dir)]).stdout.split(/\s/)
  remotes.should include remote_name
end
