require "spec_helper"
require "plist"

describe Chef::Resource::PlistResource, :macos_only, requires_root: true do
  include RecipeDSLHelper

  let(:global_prefs) do
    File.join(Dir.mktmpdir, ".GlobalPreferences.plist")
  end

  before(:each) do
    FileUtils.rm_f global_prefs
  end

  context "make Monday the first DOW" do
    it "creates a new plist with a hash value" do
      plist global_prefs do
        entry "AppleFirstWeekday"
        value(gregorian: 4)
      end
      expect(File.exist?(global_prefs))
      expect(shell_out!("/usr/libexec/PlistBuddy -c 'Print :\"AppleFirstWeekday\":gregorian' \"#{global_prefs}\"").stdout.to_i).to eq(4)
    end
  end
end
