require "spec_helper"

describe Chef::Resource::User, "initialize" do
  let(:resource) { Chef::Resource::User::LinuxUser.new("notarealuser") }

  describe "inactive attribute" do
    it "allows a string" do
      resource.inactive "100"
      expect(resource.inactive).to eql("100")
    end

    it "allows an integer" do
      resource.inactive 100
      expect(resource.inactive).to eql(100)
    end

    it "does not allow a hash" do
      expect { resource.inactive({ woot: "i found it" }) }.to raise_error(ArgumentError)
    end
  end

  describe "expire_date attribute" do
    it "allows a string" do
      resource.expire_date "100"
      expect(resource.expire_date).to eql("100")
    end

    it "does not allow an integer" do
      expect { resource.expire_date(90) }.to raise_error(ArgumentError)
    end

    it "does not allow a hash" do
      expect { resource.expire_date({ woot: "i found it" }) }.to raise_error(ArgumentError)
    end
  end

  %w{inactive expire_date}.each do |prop|
    it "sets #{prop} to nil" do
      expect(resource.send(prop)).to eql(nil)
    end
  end
end
