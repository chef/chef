
# Walk array/hash to determine maximum depth. A scalar (anything but an
# Array or Hash) has depth 0.
def count_structure_levels(obj)
  if obj.respond_to?(:keys)
    # empty hash also has depth 0.
    max_depth = 0
    obj.keys.each do |key|
      child_levels = 1 + count_structure_levels(obj[key])
      max_depth = [max_depth, child_levels].max
    end
    max_depth
  elsif obj.is_a?(Array)
    # empty array also has depth 0.
    max_depth = 0
    obj.each do |child|
      child_levels = 1 + count_structure_levels(child)
      max_depth = [max_depth, child_levels].max
    end
    max_depth
  else
    0
  end
end

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
    when 412
      self.exception.to_s.should match(/(Precondition Failed|412)/)
  end
end

Then /^the response exception body should match '(.+)'/ do |regex|
  raise "last response wasn't exception" unless self.exception
  raise "last response exception had no body" unless self.exception.response && self.exception.response.body

  self.exception.response.body.should =~ /#{regex}/m
end

Then /^the inflated responses key '(.+)' should be the integer '(\d+)'$/ do |key, int|
  inflated_response[key].should == int.to_i
end

Then /^the inflated responses key '(\w+)' should match '(.+)'$/ do |key, regex|
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
  Chef::JSONCompat.to_json(self.inflated_response).should =~ /#{regex}/m
end

Then /^the inflated responses key '(.+)' should match '(.+)' as json$/ do |key, regex|
  puts self.inflated_response.inspect if ENV["DEBUG"]
  Chef::JSONCompat.to_json(self.inflated_response[key]).should =~ /#{regex}/m
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

Then /^the inflated responses key '(.+)' item '(\d+)' should respond to '(.+)' with '(.*)'$/ do |key, index, method_name, method_value|
  inflated_response[key][index.to_i].send(method_name.to_sym).should == method_value
end

Then /^the inflated responses key '(.+)' sub-key '(.+)' should be an empty hash$/ do |key, sub_key|
  inflated_response[key][sub_key].should == {}
end

Then /^the inflated responses key '(\w+)' sub-key '(\w+)' should match '(.+)'$/ do |key, sub_key, regex|
  inflated_response[key][sub_key].should =~ /#{regex}/m
end

Then /^the inflated responses key '(\w+)' sub-key '(\w+)' item '(\d+)' sub-key '(\w+)' should match '(.+)'$/ do |key, sub_key, index, second_sub_key, regex|
  inflated_response[key][sub_key][index.to_i][second_sub_key].should =~ /#{regex}/m
end

Then /^the inflated responses key '(\w+)' sub-key '(\w+)' item '(\d+)' sub-key '(\w+)' should equal '(.+)'$/ do |key, sub_key, index, second_sub_key, equal|
  inflated_response[key][sub_key][index.to_i][second_sub_key].should == equal
end

Then /^the inflated responses key '(\w+)' sub-key '(\w+)' should be '(\d+)' items long$/ do |key, sub_key, length|
  inflated_response[key][sub_key].length.should == length.to_i
end

Then /^the inflated responses key '(\w+)' should be '(\d+)' items long$/ do |key, length|
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
    Array(inflated_response).first.should match(/#{entry}/)
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

Then "the inflated response should equal '$code'" do |code|
  # cucumber can suck it, I'm using real code.
  expected = eval(code)
  inflated_response.should == expected
end

Then /^the inflated response should respond to '(.+)' with '(.+)'$/ do |method, to_match|
  to_match = Chef::JSONCompat.from_json(to_match) if to_match =~ /^\[|\{/
  to_match = true if to_match == 'true'
  to_match = false if to_match == 'false'
  self.inflated_response.to_hash[method].should == to_match
end

Then /^the inflated response should respond to '(.+)' and match '(.+)'$/ do |method, to_match|
  self.inflated_response.to_hash[method].should == to_match
end

Then /^the inflated response should respond to '(.+)' and match '(.+)' as json$/ do |method, regex|
  Chef::JSONCompat.to_json(self.inflated_response.to_hash[method]).should =~ /#{regex}/m
end

#And the 'deep_array' component has depth of '50' levels
Then /^the '(.+)' component has depth of '(.+)' levels$/ do |method, levels|
  count_structure_levels(self.inflated_response.to_hash[method]).should == levels.to_i
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
