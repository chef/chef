Given /^I dump the contents of the search index$/ do
  rest.get_rest("/search/").each do |index_name, index_url|
    puts "INDEX NAME: `#{index_name}'"
    pp rest.get_rest(index_url.sub("http://127.0.0.1:4000", ''))
  end
end

When /^I '([^']*)' (?:to )?the path '([^']*)'$/ do |http_method, request_uri|
  begin
    self.api_response = rest.send("#{http_method}_rest".downcase.to_sym, request_uri)
    self.inflated_response = self.api_response
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

When /^I (.+) the client$/ do |action| 
  raise ArgumentError, "You can only create or save clients" unless action =~ /^(create|save)$/
  client = stash['client']
  request_body = {:name => client.name, :admin => client.admin}
  begin
    self.inflated_response = @rest.post_rest("clients", request_body) if action == 'create'
    self.inflated_response = @rest.put_rest("clients/#{client.name}", request_body) if action == 'save'
  rescue
    self.exception = $!
  end
end

When /^I '(.+)' the '(.+)' to the path '(.+)'$/ do |http_method, stash_key, request_uri|
  begin
    self.api_response = rest.send("#{http_method.to_s.downcase}_rest".downcase.to_sym, request_uri, stash[stash_key])
    self.inflated_response = self.api_response
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

When "I edit the '$not_admin' client" do |client|
  stash['client'] = @rest.get_rest("/clients/not_admin")
end
 
When "I set '$property' to true" do |property|
  stash['client'].send(property.to_sym, true)
end

def call_as_admin(&block)
  orig_rest = @rest
  orig_node_name = Chef::Config[:node_name]
  orig_client_key = Chef::Config[:client_key]
  begin
    @rest = admin_rest
    Chef::Config[:node_name] = @rest.auth_credentials.client_name
    Chef::Config[:client_key] = @rest.auth_credentials.key_file
    yield
  ensure
    @rest = orig_rest
    Chef::Config[:node_name] = orig_node_name
    Chef::Config[:client_key] = orig_client_key
  end
end
