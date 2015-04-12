require "#{ENV['BUSSER_ROOT']}/../kitchen/data/serverspec_helper"

describe "installthings::default" do
  describe package('opscode-push-jobs-client') do
    it { should be_installed }
  end
end
