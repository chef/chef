require "spec_helper"
require "chef/win32/file" if Chef::Platform.windows?

describe "OpenSSL Configuration", :windows_only do
  context "when running on Windows" do
    it "uses the embedded cacert.pem file" do
      expected_cert_path = File.join(Chef::Config.embedded_dir, "ssl", "certs", "cacert.pem")
      win_path = Chef::ReservedNames::Win32::File.canonical_path(expected_cert_path)
      
      # Get the current OpenSSL cert file path
      cert_file = OpenSSL::X509::DEFAULT_CERT_FILE
      
      # Convert both paths to Windows format for comparison
      expect(Chef::ReservedNames::Win32::File.canonical_path(cert_file))
        .to eq(win_path)
      
      # Verify the file exists
      expect(File.exist?(cert_file)).to be true
      
      # Verify it's a valid cert bundle
      expect { OpenSSL::X509::Store.new.add_file(cert_file) }
        .not_to raise_error
    end
  end
end