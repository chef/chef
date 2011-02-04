Given "the search index has been committed" do
  sleep 1 # allow time for the objects to transit rabbitmq and opscode-expander.
  RestClient.get("http://localhost:8983/solr/update?commit=true&waitFlush=true")
end

Then "there should be '$expected_count' total search results" do |expected_count|
  expected_count = expected_count.to_i
  inflated_response.should respond_to(:[])
  inflated_response.should have_key("total")
  inflated_response["total"].should == expected_count
end

Then "a '$result_item_klass' with id '$result_item_id' should be in the search result" do |result_item_klass, result_item_id|
  inflated_response.should respond_to(:[])
  inflated_response.should have_key("rows")

  result_item = inflated_response["rows"].find {|item| item["id"] == result_item_id }
  unless result_item
    msg = "expected to find a #{result_item_klass} with 'id' #{result_item_id} in the inflated response but it's not there\n"
    msg << "actual inflated response is #{inflated_response.inspect}"
    raise msg
  end
  expected_klass = eval(result_item_klass)

  result_item.should be_a_kind_of(expected_klass)
end

Given "PL-540 is resolved in favor of not removing this feature" do
  pending
end