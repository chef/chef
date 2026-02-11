require "spec_helper"

describe "openssl checks" do
  let(:openssl_version_default) do
    if macos?
      "1.1.1m"
    else
      "3.5.5"
    end
  end

  %w{version library_version}.each do |method|
    # macOS just picks up its own for some reason, maybe it circumvents a build step
    example "check #{method}", not_supported_on_macos: true, openssl_version_check: true do
      expect(OpenSSL.const_get("OPENSSL_#{method.upcase}")).to match(openssl_version_default), "OpenSSL doesn't match omnibus_overrides.rb"
    end
  end
end
