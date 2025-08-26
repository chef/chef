# Check if an apt_repository using the same key url as a previous apt_repository, actually has a working key.
if os.debian?
  describe command("gpg --no-default-keyring --keyring /etc/apt/keyrings/test-with-same-key.gpg --list-keys") do
    its(:stdout) { should match(/Debian Archive Automatic Signing Key/) }
  end
end
