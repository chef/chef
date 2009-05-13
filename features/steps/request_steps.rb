When /^I '(.+)' the path '(.+)'$/ do |http_method, request_uri|
  self.response = request(request_uri, { 
    :method => http_method, 
    "HTTP_ACCEPT" => 'application/json'
  })
  puts response.inspect if ENV['DEBUG'] == 'true'
  self.inflated_response = JSON.parse(response.body.to_s)
end

When /^I '(.+)' the '(.+)' to the path '(.+)'$/ do |http_method, stash_key, request_uri|
  self.response = request(request_uri, { 
    :method => http_method, 
    "HTTP_ACCEPT" => 'application/json',
    "CONTENT_TYPE" => 'application/json',
    :input => stash[stash_key].to_json
  })
  puts response.inspect if ENV['DEBUG'] == 'true'
  self.inflated_response = JSON.parse(response.body.to_s)
end
