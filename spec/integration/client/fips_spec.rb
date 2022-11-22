describe "chef-client fips" do
  def enable_fips_if_supported
    OpenSSL.fips_mode = true if ENV["OMNIBUS_FIPS_MODE"]
  end
  it "Should not error on enabling fips_mode" do
    expect { enable_fips_if_supported }.not_to raise_error
  end
end
