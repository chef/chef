Then /^I should see "(.*)"$/ do |text|
  response.body.to_s.should =~ /#{text}/m
end
 
Then /^I should not see "(.*)"$/ do |text|
  response.body.to_s.should_not =~ /#{text}/m
end
 
Then /^I should see an? (\w+) message$/ do |message_type|
  response.should have_xpath("//*[@class='#{message_type}']")
end
 
Then /^the (.*) ?request should fail/ do |_|
  response.should_not be_successful
end