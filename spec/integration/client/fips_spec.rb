describe "chef-client fips" do
  def enable_fips_if_supported
    OpenSSL.fips_mode = ENV["OMNIBUS_FIPS_MODE"].to_s.downcase == "true"
  end
  it "Should not error on enabling fips_mode" do
    expect { enable_fips_if_supported }.not_to raise_error
  end
end
