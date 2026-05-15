require "spec_helper"

describe "openssl checks" do
  let(:openssl_version_default) do
    if macos?
      "1.1.1m"
    else
      # this will break whenever your upstream openssl version changes, but this is meant to make
      # sure we're actually using the version we expect to be using, and not some system version that might be present on the build machine
      "3.5.6"
    end
  end

  %w{version library_version}.each do |method|
    # macOS just picks up its own for some reason, maybe it circumvents a build step
    example "check #{method}", not_supported_on_macos: true, openssl_version_check: true do
      actual_version = OpenSSL.const_get("OPENSSL_#{method.upcase}")
      expect(actual_version).to match(openssl_version_default), "OpenSSL doesn't match packaged build version expectation (expected match: #{openssl_version_default.inspect}, actual: #{actual_version.inspect})"
    end
  end
end
