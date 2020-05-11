require "spec_helper"
require "chef/resource/helpers/cron"

describe Chef::ResourceHelpers::Cron do

  describe "#weekday_in_crontab" do
    context "when weekday is symbol with full name as a day of week" do
      it "should return weekday in crontab standard format" do
        expect(Chef::ResourceHelpers::Cron.weekday_in_crontab(:wednesday)).to eq("3")
      end
    end

    context "when weekday is a number in a string" do
      it "should return the string" do
        expect(Chef::ResourceHelpers::Cron.weekday_in_crontab("3")).to eq("3")
      end
    end

    context "when weekday is string with the short name as a day of week" do
      it "should return the number string in crontab standard format" do
        expect(Chef::ResourceHelpers::Cron.weekday_in_crontab("mon")).to eq("1")
      end
    end

    context "when weekday is an integer" do
      it "should return the integer" do
        expect(Chef::ResourceHelpers::Cron.weekday_in_crontab(1)).to eq(1)
      end
    end
  end
end
