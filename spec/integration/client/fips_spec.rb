require "spec_helper"

describe "chef-client fips" do
  def enable_fips
    OpenSSL.fips_mode = true
  end

  # All tests assume fips mode is off at present
  after { OpenSSL.fips_mode = false }

  # For non-FIPS OSes/builds of Ruby, enabling FIPS should error
  example "Error enabling fips_mode if FIPS not linked", fips_mode: false do
    expect { enable_fips }.to raise_error(OpenSSL::OpenSSLError)
  end

  # For FIPS OSes/builds of Ruby, enabling FIPS should not error
  example "Do not error enabling fips_mode if FIPS linked", fips_mode: true do
    expect { enable_fips }.not_to raise_error
  end
end
