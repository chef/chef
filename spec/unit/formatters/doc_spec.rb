#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

describe Chef::Formatters::Base do

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  subject(:formatter) { Chef::Formatters::Doc.new(out, err) }

  it "prints a policyfile's name and revision ID" do
    minimal_policyfile = {
      "revision_id" => "613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073",
      "name" => "jenkins",
      "run_list" => [
        "recipe[apt::default]",
        "recipe[java::default]",
        "recipe[jenkins::master]",
        "recipe[policyfile_demo::default]",
      ],
      "cookbook_locks" => {},
    }

    formatter.policyfile_loaded(minimal_policyfile)
    expect(out.string).to include("Using policy 'jenkins' at revision '613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073'")
  end

  it "prints cookbook name and version" do
    cookbook_version = double(name: "apache2", version: "1.2.3")
    formatter.synchronized_cookbook("apache2", cookbook_version)
    expect(out.string).to include("- apache2 (1.2.3")
  end

  it "prints only seconds when elapsed time is less than 60 seconds" do
    @now = Time.now
    allow(Time).to receive(:now).and_return(@now, @now + 10.0)
    formatter.run_completed(nil)
    expect(formatter.elapsed_time).to eql(10.0)
    expect(formatter.pretty_elapsed_time).to include("10 seconds")
    expect(formatter.pretty_elapsed_time).not_to include("minutes")
    expect(formatter.pretty_elapsed_time).not_to include("hours")
  end

  it "prints minutes and seconds when elapsed time is more than 60 seconds" do
    @now = Time.now
    allow(Time).to receive(:now).and_return(@now, @now + 610.0)
    formatter.run_completed(nil)
    expect(formatter.elapsed_time).to eql(610.0)
    expect(formatter.pretty_elapsed_time).to include("10 minutes 10 seconds")
    expect(formatter.pretty_elapsed_time).not_to include("hours")
  end

  it "prints hours, minutes and seconds when elapsed time is more than 3600 seconds" do
    @now = Time.now
    allow(Time).to receive(:now).and_return(@now, @now + 36610.0)
    formatter.run_completed(nil)
    expect(formatter.elapsed_time).to eql(36610.0)
    expect(formatter.pretty_elapsed_time).to include("10 hours 10 minutes 10 seconds")
  end

  it "shows the percentage completion of an action" do
    res = Chef::Resource::RemoteFile.new("canteloupe")
    formatter.resource_update_progress(res, 35, 50, 10)
    expect(out.string).to include(" - Progress: 70%")
  end

  it "updates the percentage completion of an action" do
    res = Chef::Resource::RemoteFile.new("canteloupe")
    formatter.resource_update_progress(res, 70, 100, 10)
    expect(out.string).to include(" - Progress: 70%")
    formatter.resource_update_progress(res, 80, 100, 10)
    expect(out.string).to include(" - Progress: 80%")
  end
end
