# Upload the given file to the sandbox which was created by 'when I create a
# sandbox named'
def upload_to_sandbox(sandbox_filename)
  sandbox_file_checksum = Chef::CookbookVersion.checksum_cookbook_file(sandbox_filename)

  url = "#{self.sandbox_url}/#{sandbox_file_checksum}"
  File.open(sandbox_filename, "r") do |sandbox_file|
    payload = {
      :name => sandbox_filename,
      :file => sandbox_file,
    }
    
    self.exception = nil
    self.response = Chef::StreamingCookbookUploader.put(url, rest.client_name, rest.signing_key_filename, payload)
    self.inflated_response = JSON.parse(self.response.to_s)
  end
end
  

When /^I create a sandbox named '([^\']+)'$/ do |sandbox_name|
  begin
    sandbox = get_fixture('sandbox', sandbox_name)
    raise "no such sandbox in fixtures: #{sandbox_name}" unless sandbox
    
    @stash['sandbox'] = sandbox
    
    self.response = nil
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
    self.response = nil
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
    
    upload_to_sandbox(sandbox_filename)
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
    url = "#{self.sandbox_url}/#{use_checksum}"
    
    File.open(sandbox_upload_filename, "r") do |file_to_upload|
      payload = {
        :name => stash_upload_filename,
        :file => file_to_upload
      }
      self.exception = nil
      self.response = Chef::StreamingCookbookUploader.put(url, rest.client_name, rest.signing_key_filename, payload)
      self.inflated_response = JSON.parse(self.response.to_s)
    end
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

