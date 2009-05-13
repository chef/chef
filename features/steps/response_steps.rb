Then /^the response code should be '(.+)'$/ do |response_code|
  response.status.should == response_code.to_i
end

Then /^the inflated responses key '(.+)' should match '(.+)'$/ do |key, regex|
  inflated_response[key].should =~ /#{regex}/
end

Then /^the inflated responses key '(.+)' should not exist$/ do |key|
  inflated_response.has_key?(key).should == false
end

Then /^the inflated responses key '(.+)' should exist$/ do |key|
  inflated_response.has_key?(key).should == true 
end

Then /^the inflated response should be an empty array$/ do
  inflated_response.should == []
end

Then /^the inflated response should include '(.+)'$/ do |entry|
  inflated_response.detect { |n| n =~ /#{entry}/ }.should be(true)
end

Then /^the inflated response should be '(.+)' items long$/ do |length|
  inflated_response.length.should == length.to_i
end

Then /^the '(.+)' header should match '(.+)'$/ do |header, regex|
  response.headers[header].should =~ /#{regex}/
end

Then /^the inflated responses key '(.+)' should include '(.+)'$/ do |key, regex|
  inflated_response[key].detect { |n| n =~ /#{regex}/ }.should be(true)
end

Then /^the inflated response should match the '(.+)'$/ do |stash_name|
  stash[stash_name].each do |k,v|
    inflated_response[k.to_s].should == v
  end
end

Then /^the fields in the inflated response should match the '(.+)'$/ do |stash_name|
  inflated_response.each do |k,v|
    unless k =~ /^_/ || k == 'couchrest-type'
      stash[stash_name][k.to_sym].should == v
    end
  end
end

