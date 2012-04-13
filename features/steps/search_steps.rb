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

Then "a '$result_item_klass' with item name '$result_item_name' should be in the search result" do |result_item_klass, result_item_name|
  inflated_response.should respond_to(:[])
  inflated_response.should have_key("rows")

  found_match = false
  expected_klass = eval(result_item_klass)

  inflated_response['rows'].each do |item|
    next unless item.name == result_item_name
    found_match = true
    item.should be_a_kind_of(expected_klass)
  end

  unless found_match
    msg = "expected to find a #{result_item_klass} with item name #{result_item_name} in the inflated response but it's not there\n"
    msg << "actual inflated response is #{inflated_response.inspect}"
    raise msg
  end
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

Given /^a set of nodes pre-populated with known, searchable data$/ do
  node_script = File.join(datadir, 'search-tests', 'search-test-nodes.rb')
  shell_out! "knife exec #{get_knife_config} < #{node_script}", :timeout => 240
end

When /^I execute a randomized set of searches across my infrastructure$/ do
  search_script = File.join(datadir, 'search-tests', 'do_knife_search_test.rb')
  @shell_result = shell_out "knife exec #{get_knife_config} < #{search_script}"
end

Then /^all of the searches should return the expected results$/ do
  io = StringIO.new(@shell_result.stdout)
  while io.eof? == false
    l = io.readline
    next unless l =~ /^(OK|FAIL|ERROR)/
    case $1
    when "OK"
      next
    when "FAIL"
      message = [l, io.readline, io.readline].join("\n")
      puts @shell_result.stdout
      raise message
    when "ERROR"
      puts @shell_result.stdout
      raise l
    end
  end
end

# return a set of knife command line parameters that
# are based on the current Chef::Rest config being
# used by the feature tests
def get_knife_config
  [
    "--user",       @rest.auth_credentials.client_name,
    "--server-url", @rest.url,
    "--key",        @rest.auth_credentials.key_file
  ].join(" ")
end
