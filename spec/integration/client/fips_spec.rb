describe "chef-client fips" do
  def enable_fips_if_supported
    if ENV["OMNIBUS_FIPS_MODE"].to_s.downcase == "true"
      OpenSSL.fips_mode = true
      # This is a really bizarre thing, yes, but in my testing
      # I found that I was getting false negatives on whether
      # fips_mode was broken due to exiting the process before
      # whatever cascade of things behind the scenes needed to happen
      # happened.
      OpenSSL.fips_mode = false
    end
  end
  it "Should not error on enabling fips_mode" do
    expect { enable_fips_if_supported }.not_to raise_error
  end
end
