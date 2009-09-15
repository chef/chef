Given /^I have a clone of typo in the data\/tmp dir$/ do
  cmd = "git clone #{datadir}/typo.bundle #{tmpdir}/gitrepo/typo"
  `#{cmd}`
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