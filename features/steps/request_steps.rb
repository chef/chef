When /^I '(.+)' the path '(.+)'$/ do |http_method, request_uri|
  begin
    self.response = rest.send("#{http_method}_rest".downcase.to_sym, request_uri)
    self.inflated_response = self.response 
  rescue
    self.exception = $!
  end
end

When /^I '(.+)' the '(.+)' to the path '(.+)'$/ do |http_method, stash_key, request_uri|
  begin
    self.response = rest.send("#{http_method}_rest".downcase.to_sym, request_uri, stash[stash_key])
    self.inflated_response = response
  rescue
    self.exception = $!
  end
end

When /^I authenticate as '(.+)'$/ do |reg|
  begin
    rest.authenticate(reg, 'tclown')
  rescue
    self.exception = $!
  end
end

