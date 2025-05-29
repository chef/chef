require "spec_helper"

describe "openssl checks" do
  let(:openssl_version_default) do
    if windows?
      "3.0.9"
    elsif macos?
      "1.1.1m"
    else
      "3.0.9"
    end
  end

  %w{version library_version}.each do |method|
    # macOS just picks up its own for some reason, maybe it circumvents a build step
    example "check #{method}", not_supported_on_macos: true do
      expect(OpenSSL.const_get("OPENSSL_#{method.upcase}")).to match(openssl_version_default), "OpenSSL doesn't match omnibus_overrides.rb"
    end
  end

  example "check SSL_ENV_HACK", windows_only: true do
    expect(SSL_ENV_HACK).to be_defined, "SSL_ENV_HACK is not defined, did you forget to include the openssl-customization.rb file in your project?"
  end
end
