require "spec_helper"

describe "openssl checks" do
  let(:openssl_version_default) do
    if windows? || aix?
      "1.0.2zi"
    elsif macos?
      "1.1.1m"
    else
      "3.0.9"
    end
  end

  %w{version library_version}.each do |method|
    # macOS just picks up its own for some reason, maybe it circumvents a build step
    example "check #{method}", openssl_version_check: true, not_supported_on_macos: true do
      expect(OpenSSL.const_get("OPENSSL_#{method.upcase}")).to match(openssl_version_default), "OpenSSL doesn't match omnibus_overrides.rb"
    end
  end
end