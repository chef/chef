require 'chef/sandbox'

# Upload the given file to the sandbox which was created by 'when I create a
# sandbox named'
def upload_to_sandbox(sandbox_filename, sandbox_file_checksum, url)

  checksum64 = Base64.encode64([sandbox_file_checksum].pack("H*")).strip
  timestamp = Time.now.utc.iso8601
  file_contents = File.read(sandbox_filename)
  # TODO - 5/28/2010, cw: make signing and sending the request streaming
  sign_obj = Mixlib::Authentication::SignedHeaderAuth.signing_object(
                                                                     :http_method => :put,
                                                                     :path => URI.parse(url).path,
                                                                     :body => file_contents,
                                                                     :timestamp => timestamp,
                                                                     :user_id => rest.client_name
                                                                     )
  headers = {
    'content-type' => 'application/x-binary',
    'content-md5' => checksum64,
    :accept => 'application/json'
  }
  headers.merge!(sign_obj.sign(OpenSSL::PKey::RSA.new(rest.signing_key)))

  # Don't set inflated_response as S3 (for the Platform) doesn't return JSON.
  # Only Open Source does.
  self.inflated_response = nil
  self.exception = nil
  self.api_response = RestClient::Request.execute(
    :method => :put,
    :url => url,
    :headers => headers,
    :payload => file_contents
  )
end


When /^I create a sandbox named '([^\']+)'$/ do |sandbox_name|
  begin
    sandbox = get_fixture('sandbox', sandbox_name)
    raise "no such sandbox in fixtures: #{sandbox_name}" unless sandbox

    @stash['sandbox'] = sandbox

    self.api_response = nil
    self.exception = nil
    self.inflated_response = rest.post_rest('/sandboxes', sandbox)
    self.sandbox_url = self.inflated_response['uri']

    @stash['sandbox_response'] = self.inflated_response
  rescue
    Chef::Log.debug("Caught exception in sandbox create (POST) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

When /^I commit the sandbox$/ do
  begin
    sandbox = @stash['sandbox']

    # sandbox_url is fully qualified (with http://, sandboxes, etc.)
    self.api_response = nil
    self.exception = nil
    self.inflated_response = rest.put_rest("#{self.sandbox_url}", {:is_completed => true})

    @stash.delete('sandbox_response')
  rescue
    Chef::Log.debug("Caught exception in sandbox commit (PUT) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

Then /^I upload a file named '([^\']+)' to the sandbox$/ do |stash_sandbox_filename|
  begin
    sandbox = @stash['sandbox']
    raise "no sandbox defined, have you called 'When I create a sandbox'" unless sandbox

    sandbox_filename = get_fixture('sandbox_file', stash_sandbox_filename)
    raise "no such stash_sandbox_filename in fixtures: #{stash_sandbox_filename}" unless sandbox_filename

    sandbox_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(sandbox_filename)
    if @stash['sandbox_response']['checksums'].key?(sandbox_file_checksum)
      Chef::Log.debug "uploading a file '#{stash_sandbox_filename}' with correct checksum #{sandbox_file_checksum}"
      url = @stash['sandbox_response']['checksums'][sandbox_file_checksum]['url']
    else
      Chef::Log.debug "Sandbox doesn't have a checksum #{sandbox_file_checksum}, assuming a negative test"
      Chef::Log.debug "using checksum 'F157'... just kidding, using #{sandbox_file_checksum}"
      url = @stash['sandbox_response']['uri'] + "/#{sandbox_file_checksum}"
    end

    upload_to_sandbox(sandbox_filename, sandbox_file_checksum, url)
  rescue
    Chef::Log.debug("Caught exception in sandbox checksum upload (PUT) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

# Upload a file sandbox_filename_to_upload, but post it to the URL specified by
# sandbox_file_for_checksum, to cause the checksum check to fail.
Then /^I upload a file named '([^\']+)' using the checksum of '(.+)' to the sandbox$/ do |stash_upload_filename, stash_checksum_filename|
  begin
    sandbox = @stash['sandbox']

    sandbox_upload_filename = get_fixture('sandbox_file', stash_upload_filename)
    sandbox_checksum_filename = get_fixture('sandbox_file', stash_checksum_filename)
    raise "no such stash_upload_filename in fixtures: #{stash_upload_filename}" unless sandbox_upload_filename
    raise "no such stash_checksum_filename in fixtures: #{stash_checksum_filename}" unless stash_checksum_filename

    use_checksum = Chef::CookbookVersion.checksum_cookbook_file(sandbox_checksum_filename)
    url = @stash['sandbox_response']['checksums'][use_checksum]['url']

    upload_to_sandbox(sandbox_upload_filename, use_checksum, url)
  rescue
    Chef::Log.debug("Caught exception in bad sandbox checksum upload (PUT) request: #{$!.message}: #{$!.backtrace.join("\n")}")
    self.exception = $!
  end
end

#Then the sandbox file 'sandbox2_file1' should need upload
Then /^the sandbox file '(.+)' should need upload$/ do |stash_filename|
  sandbox = @stash['sandbox_response']

  sandbox_filename = get_fixture('sandbox_file', stash_filename)
  sandbox_checksum = Chef::CookbookVersion.checksum_cookbook_file(sandbox_filename)

  sandbox['checksums'][sandbox_checksum]['needs_upload'] == true
end

Then /^the sandbox file '(.+)' should not need upload$/ do |stash_filename|
  sandbox = @stash['sandbox_response']

  sandbox_filename = get_fixture('sandbox_file', stash_filename)
  sandbox_checksum = Chef::CookbookVersion.checksum_cookbook_file(sandbox_filename)

  sandbox['checksums'][sandbox_checksum]['needs_upload'] == false
end

