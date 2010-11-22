Then /^I should get a '(.+)' exception$/ do |exception|
  self.exception.message.to_s.should == exception
end

Then /^I should not get an exception$/ do
  self.exception.should == nil
end

Then /^the response code should be '(.+)'$/ do |response_code|
  case response_code.to_i
    when 200
      self.api_response.code.should == 200
    when 400
      self.exception.to_s.should match(/(Bad Request|400)/)
    when 404
      Then "I should get a 'RestClient::ResourceNotFound' exception"
  end
end

Then /^the inflated responses key '(.+)' should be the integer '(\d+)'$/ do |key, int|
  inflated_response[key].should == int.to_i
end

Then /^the inflated responses key '(.+)' should match '(.+)'$/ do |key, regex|
  puts self.inflated_response.inspect if ENV['DEBUG']
  self.inflated_response[key].should =~ /#{regex}/m  
end

Then /^the inflated responses key '(.+)' should be literally '(.+)'$/ do |key, literal|
  puts self.inflated_response.inspect if ENV['DEBUG']
  to_check = case literal
             when "true"
               true
             when "false"
               false
             end

  self.inflated_response[key].should == to_check 
end

Then /^the inflated response should match '(.+)' as json$/ do |regex|
  puts self.inflated_response.inspect if ENV["DEBUG"]
  Chef::JSON.to_json(self.inflated_response).should =~ /#{regex}/m
end

Then /^the inflated responses key '(.+)' should match '(.+)' as json$/ do |key, regex|
  puts self.inflated_response.inspect if ENV["DEBUG"]
  Chef::JSON.to_json(self.inflated_response[key]).should =~ /#{regex}/m
end

Then /^the inflated responses key '(.+)' item '(\d+)' should be '(.+)'$/ do |key, index, to_equal|
  inflated_response[key][index.to_i].should == to_equal
end

Then /^the inflated responses key '(.+)' item '(\d+)' should be a kind of '(.+)'$/ do |key, index, constant|
  inflated_response[key][index.to_i].should be_a_kind_of(eval(constant))
end

Then /^the inflated responses key '(.+)' item '(\d+)' key '(.+)' should be '(.+)'$/ do |key, index, sub_key, to_equal|
  inflated_response[key][index.to_i][sub_key].should == to_equal
end

Then /^the inflated responses key '(.+)' sub-key '(.+)' should be an empty hash$/ do |key, sub_key|
  inflated_response[key][sub_key].should == {}
end

Then /^the inflated responses key '(.+)' should be '(\d+)' items long$/ do |key, length| 
  inflated_response[key].length.should == length.to_i
end

Then /^the inflated responses key '(.+)' should not exist$/ do |key|
  self.inflated_response.has_key?(key).should == false
end

Then /^the inflated responses key '(.+)' should exist$/ do |key|
  self.inflated_response.has_key?(key).should == true 
end

Then /^the inflated responses key '(.+)'.to_s should be '(.+)'$/ do |key, expected_value|
  self.inflated_response[key].to_s.should == expected_value
end

Then /^the inflated response should be an empty array$/ do
  self.inflated_response.should == []
end

Then /^the inflated response should be an empty hash$/ do
  self.inflated_response.should == {} 
end

Then /^the inflated response should include '(.+)'$/ do |entry|
  if inflated_response.size == 1
    inflated_response.should match(/#{entry}/)
  else
    inflated_response.detect { |n| n =~ /#{entry}/ }.should_not be_empty
  end
end

Then /^the inflated response should be '(.+)' items long$/ do |length|
  if length.respond_to?(:keys)
    self.inflated_response.keys.length.should == length.to_i
  else
    self.inflated_response.length.should == length.to_i
  end
end

Then /^the '(.+)' header should match '(.+)'$/ do |header, regex|
  self.api_response.headers[header].should =~ /#{regex}/
end

Then /^the inflated responses key '(.+)' should include '(.+)'$/ do |key, regex|
  if self.inflated_response[key].size == 1
    self.inflated_response[key].first.should match(/#{regex}/)
  else
    self.inflated_response[key].detect { |n| n =~ /#{regex}/ }.should_not be_empty
  end
end

Then /^the inflated response should match the '(.+)'$/ do |stash_name|
  stash[stash_name].each do |k,v|
    self.inflated_response[k.to_s].should == v
  end
end

Then /^the inflated response should be the '(.+)'$/ do |stash_key|
  self.inflated_response.should == stash[stash_key]
end

Then /^the stringified response should be the stringified '(.+)'$/ do |stash_key|
  self.api_response.to_s.should == stash[stash_key].to_s
end

Then /^the inflated response should be a kind of '(.+)'$/ do |thing|
  self.inflated_response.should be_a_kind_of(eval(thing))
end

Then /^the inflated response should respond to '(.+)' with '(.+)'$/ do |method, to_match|
  to_match = Chef::JSON.from_json(to_match) if to_match =~ /^\[|\{/
  to_match = true if to_match == 'true'
  to_match = false if to_match == 'false'
  self.inflated_response.to_hash[method].should == to_match 
end

Then /^the inflated response should respond to '(.+)' and match '(.+)'$/ do |method, to_match|
  self.inflated_response.to_hash[method].should == to_match
end

Then /^the inflated response should respond to '(.+)' and match '(.+)' as json$/ do |method, regex|
  Chef::JSON.to_json(self.inflated_response.to_hash[method]).should =~ /#{regex}/m
end

Then /^the fields in the inflated response should match the '(.+)'$/ do |stash_name|
  self.inflated_response.each do |k,v|
    unless k =~ /^_/ || k == 'couchrest-type'
      stash[stash_name][k.to_sym].should == v
    end
  end
end

Then /^the data_bag named '(.+)' should not have an item named '(.+)'$/ do |data_bag, item|
  exists = true
  begin
    Chef::DataBagItem.load(data_bag, item, @couchdb)
  rescue
    exists = false
  end
  exists.should == false
end
