Given /^I dump the contents of the search index$/ do
  rest.get_rest("/search/").each do |index_name, index_url|
    puts "INDEX NAME: `#{index_name}'"
    pp rest.get_rest(index_url.sub("http://127.0.0.1:4000", ''))
  end
end

When /^I '([^']*)' (?:to )?the path '([^']*)'$/ do |http_method, request_uri|
  begin
    self.response = rest.send("#{http_method}_rest".downcase.to_sym, request_uri)
    self.inflated_response = self.response
  rescue
    Chef::Log.debug("Caught exception in request: #{$!.message}")
    self.exception = $!
  end
end

When /^I '(.+)' the path '(.+)' using a wrong private key$/ do |http_method, request_uri|
  key = OpenSSL::PKey::RSA.generate(2048)
  File.open(File.join(tmpdir, 'false_key.pem'), "w") { |f| f.print key }
  @rest = Chef::REST.new(Chef::Config[:chef_server_url], 'snakebite' , File.join(tmpdir, 'false_key.pem'))

  When "I '#{http_method}' the path '#{request_uri}'"
end

When /^I '(.+)' the '(.+)' to the path '(.+)'$/ do |http_method, stash_key, request_uri|
  begin
    self.response = rest.send("#{http_method.to_s.downcase}_rest".downcase.to_sym, request_uri, stash[stash_key])
    self.inflated_response = response
  rescue
    self.exception = $!
  end
end

When /^I '(.+)' the '(.+)' to the path '(.+)' using a wrong private key$/ do |http_method, stash_key, request_uri|
  key = OpenSSL::PKey::RSA.generate(2048)
  File.open(File.join(tmpdir, 'false_key.pem'), "w") { |f| f.print key }
  @rest = Chef::REST.new(Chef::Config[:chef_server_url], 'snakebite' , File.join(tmpdir, 'false_key.pem'))

  When "I '#{http_method}' the '#{stash_key}' to the path '#{request_uri}'"
end

When /^I delete local private key/ do
  Chef::FileCache.delete("private_key.pem")
end

When /^I register '(.+)'$/ do |user|
  begin
    rest = Chef::REST.new(Chef::Config[:registration_url])
    rest.register("bobo")
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

#When /^I dump the contents of the search index$/ do
#  Given "I dump the contents of the search index"
#end
#

# When /^I '(.+)' the path '(.+)'$/ do |http_method, request_uri|
#   begin
#     #if http_method.downcase == 'get'
#     #  self.response = @rest.get_rest(request_uri)
#     #else
#       #puts "test test test \n\n\n\n\n\n\n"
#       @response = @rest.send("#{http_method}_rest".downcase.to_sym, request_uri)
#     #end
#     puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#     puts @response
#     puts @response['content-type']
#     #puts self.response
#     #puts self.response.inspect
#     #self.inflated_response = self.response
#     @inflated_response = @response#JSON.parse(response.body.to_s) 
#     puts "~~~~~~~~INFLATED RESPONSE~~~~~~~~~~~~"
#     puts @inflated_response
#   rescue
#     self.exception = $!
#   end
# end
# 
# When /^I '(.+)' the '(.+)' to the path '(.+)'$/ do |http_method, stash_key, request_uri|
#   begin
#     #if http_method.downcase == 'post'
#     #  puts "post request"
#     #  self.response = @rest.post_rest(request_uri, @stash[stash_key])
#     #  puts self.response
#     #else
#     puts "This is the request -- @stash[stash_key]:" 
#     puts @stash[stash_key].to_s
#     @response = @rest.send("#{http_method}_rest".downcase.to_sym, request_uri, @stash[stash_key])
#     #end
#     puts "This is the response:"
#     #puts self.response.body.to_s
#     puts @response
#     #self.inflated_response = response
#     @inflated_response = @response#JSON.parse(self.response.body.to_s)
#     puts "~~~~~~~~INFLATED RESPONSE~~~~~~~~~~~~"
#     puts @inflated_response
#   rescue
#     self.exception = $!
#   end
# end
# 
# When /^I authenticate as '(.+)'$/ do |reg|
#   begin
#     rest.authenticate(reg, 'tclown')
#   rescue
#     self.exception = $!
#   end
# end
# 
