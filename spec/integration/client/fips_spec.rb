describe "chef-client fips", :windows_only do
   it "Should not error on enabling fips_mode" do
     expect { OpenSSL.fips_mode = true }.not_to raise_error(OpenSSL::OpenSSLError, /fingerprint/)
   end
 end
