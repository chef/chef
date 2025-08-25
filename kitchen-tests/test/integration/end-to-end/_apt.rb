# Check if an apt_repository using the same key url as a previous apt_repository, actually has a working key.
if os.platform_family_name == "debian"
  describe command("gpg --no-default-keyring --keyring /etc/apt/keyrings/test-with-same-key.gpg --list-keys") do
    its(:stdout) { should match(%r{Debian Archive Automatic Signing Key (12/bookworm) <ftpmaster@debian.org>}) }
  end
end
