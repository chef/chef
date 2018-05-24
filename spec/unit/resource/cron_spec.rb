#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Bryan McLellan
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Resource::Cron do
  let(:resource) { Chef::Resource::Cron.new("cronify") }

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "allows you to set a command" do
    resource.command "/bin/true"
    expect(resource.command).to eql("/bin/true")
  end

  it "allows you to set a user" do
    resource.user "daemon"
    expect(resource.user).to eql("daemon")
  end

  it "allows you to specify the minute" do
    resource.minute "30"
    expect(resource.minute).to eql("30")
  end

  it "allows you to specify the hour" do
    resource.hour "6"
    expect(resource.hour).to eql("6")
  end

  it "allows you to specify the day" do
    resource.day "10"
    expect(resource.day).to eql("10")
  end

  it "allows you to specify the month" do
    resource.month "10"
    expect(resource.month).to eql("10")
  end

  it "allows you to specify the weekday" do
    resource.weekday "2"
    expect(resource.weekday).to eql("2")
  end

  it "allows you to specify the mailto variable" do
    resource.mailto "test@example.com"
    expect(resource.mailto).to eql("test@example.com")
  end

  it "allows you to specify the path" do
    resource.path "/usr/bin:/usr/sbin"
    expect(resource.path).to eql("/usr/bin:/usr/sbin")
  end

  it "allows you to specify the home directory" do
    resource.home "/root"
    expect(resource.home).to eql("/root")
  end

  it "allows you to specify the shell to run the command with" do
    resource.shell "/bin/zsh"
    expect(resource.shell).to eql("/bin/zsh")
  end

  it "allows you to specify environment variables hash" do
    env = { "TEST" => "LOL" }
    resource.environment env
    expect(resource.environment).to eql(env)
  end

  it "allows * for all time and date values" do
    %w{minute hour day month weekday}.each do |x|
      expect(resource.send(x, "*")).to eql("*")
    end
  end

  it "allows ranges for all time and date values" do
    %w{minute hour day month weekday}.each do |x|
      expect(resource.send(x, "1-2,5")).to eql("1-2,5")
    end
  end

  it "has a default value of * for all time and date values" do
    %w{minute hour day month weekday}.each do |x|
      expect(resource.send(x)).to eql("*")
    end
  end

  it "has a default value of root for the user" do
    expect(resource.user).to eql("root")
  end

  it "rejects any minute over 59" do
    expect { resource.minute "60" }.to raise_error(RangeError)
  end

  it "rejects any hour over 23" do
    expect { resource.hour "24" }.to raise_error(RangeError)
  end

  it "rejects any day over 31" do
    expect { resource.day "32" }.to raise_error(RangeError)
  end

  it "rejects any month over 12" do
    expect { resource.month "13" }.to raise_error(RangeError)
  end

  describe "weekday" do
    it "rejects any weekday over 7" do
      expect { resource.weekday "8" }.to raise_error(RangeError)
    end
    it "rejects any symbols which don't represent day of week" do
      expect { resource.weekday :foo }.to raise_error(RangeError)
    end
  end

  it "converts integer schedule values to a string" do
    %w{minute hour day month weekday}.each do |x|
      expect(resource.send(x, 5)).to eql("5")
    end
  end

  describe "when it has a time (minute, hour, day, month, weeekend) and user" do
    before do
      resource.command("tackle")
      resource.minute("1")
      resource.hour("2")
      resource.day("3")
      resource.month("4")
      resource.weekday("5")
      resource.user("root")
    end

    it "describes the state" do
      state = resource.state_for_resource_reporter
      expect(state[:minute]).to eq("1")
      expect(state[:hour]).to eq("2")
      expect(state[:day]).to eq("3")
      expect(state[:month]).to eq("4")
      expect(state[:weekday]).to eq("5")
      expect(state[:user]).to eq("root")
    end

    it "returns the command as its identity" do
      expect(resource.identity).to eq("tackle")
    end
  end
end
