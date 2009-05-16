Then /^I should get a '(.+)' exception$/ do |exception|
  self.exception.to_s.should == exception
end

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

Then /^the inflated response should be the '(.+)'$/ do |stash_key|
  stash[stash_key].should == inflated_response
end

Then /^the inflated response should be a kind of '(.+)'$/ do |thing|
  inflated_response.should be_a_kind_of(thing)
end

Then /^the inflated response should respond to '(.+)' with '(.+)'$/ do |method, to_match|
  to_match = JSON.parse(to_match) if to_match =~ /^\[|\{/
  inflated_response.send(method.to_sym).should == to_match 
end

Then /^the inflated response should respond to '(.+)' and match '(.+)'$/ do |method, to_match|
  inflated_response.send(method.to_sym).should == to_match 
end


Then /^the fields in the inflated response should match the '(.+)'$/ do |stash_name|
  inflated_response.each do |k,v|
    unless k =~ /^_/ || k == 'couchrest-type'
      stash[stash_name][k.to_sym].should == v
    end
  end
end

