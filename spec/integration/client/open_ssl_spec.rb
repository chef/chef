require "spec_helper"
require "openssl"

describe "openssl checks" do
  let(:openssl_version_default) do
    if aix?
      "3.2.4" # older chef-foundation
    elsif macos?
      "1.1.1m"
    else
      "3.2.6"
    end
  end

  %w{version library_version}.each do |method|
    # macOS just picks up its own for some reason, maybe it circumvents a build step
    example "check #{method}", not_supported_on_macos: true do
      expect(OpenSSL.const_get("OPENSSL_#{method.upcase}")).to match(openssl_version_default), "OpenSSL doesn't match omnibus_overrides.rb, it is #{OpenSSL.const_get("OPENSSL_#{method.upcase}")} instead of #{openssl_version_default}"
    end
  end

  example "check SSL_ENV_HACK", windows_only: true, validate_only: true do
    expect(defined?(::SSL_ENV_CACERT_PATCH)).to be_truthy, "SSL_ENV_CACERT_PATCH is not defined, did you forget to include the openssl-customization.rb file in your project?"
  end
end
