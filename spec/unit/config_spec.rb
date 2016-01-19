
require "spec_helper"

require "chef/config"

RSpec.describe Chef::Config do

  shared_examples_for "deprecated by ohai but not deprecated" do
    it "does not emit a deprecation warning when set" do
      expect(Chef::Log).to_not receive(:warn).
        with(/Ohai::Config\[:#{option}\] is deprecated/)
      Chef::Config[option] = value
      expect(Chef::Config[option]).to eq(value)
    end
  end

  describe ":log_level" do
    include_examples "deprecated by ohai but not deprecated" do
      let(:option) { :log_level }
      let(:value) { :debug }
    end
  end

  describe ":log_location" do
    include_examples "deprecated by ohai but not deprecated" do
      let(:option) { :log_location }
      let(:value) { "path/to/log" }
    end
  end

end
