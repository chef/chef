#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Deploy::Revision do

  before do
    allow(ChefConfig).to receive(:windows?) { false }
    @temp_dir = Dir.mktmpdir
    Chef::Config[:file_cache_path] = @temp_dir
    @resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    @resource.revision("8a3195bf3efa246f743c5dfa83683201880f935c")
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @provider = Chef::Provider::Deploy::Revision.new(@resource, @run_context)
    @provider.load_current_resource
    @runner = double("runnah")
    allow(Chef::Runner).to receive(:new).and_return(@runner)
    @expected_release_dir = "/my/deploy/dir/releases/8a3195bf3efa246f743c5dfa83683201880f935c"
  end

  after do
    # Make sure we don't keep any state in our tests
    FileUtils.rm_rf @temp_dir if File.directory?( @temp_dir )
  end

  it "uses the resolved revision from the SCM as the release slug" do
    allow(@provider.scm_provider).to receive(:revision_slug).and_return("uglySlugly")
    expect(@provider.send(:release_slug)).to eq("uglySlugly")
  end

  it "deploys to a dir named after the revision" do
    expect(@provider.release_path).to eq(@expected_release_dir)
  end

  it "stores the release dir in the file cache in the cleanup step" do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    @provider.cleanup!
    allow(@provider).to receive(:release_slug).and_return("73219b87e977d9c7ba1aa57e9ad1d88fa91a0ec2")
    @provider.load_current_resource
    @provider.cleanup!
    second_release = "/my/deploy/dir/releases/73219b87e977d9c7ba1aa57e9ad1d88fa91a0ec2"

    expect(@provider.all_releases).to eq([@expected_release_dir, second_release])
  end

  it "removes a release from the file cache when it's used again in another release and append it to the end" do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    @provider.cleanup!
    allow(@provider).to receive(:release_slug).and_return("73219b87e977d9c7ba1aa57e9ad1d88fa91a0ec2")
    @provider.load_current_resource
    @provider.cleanup!
    second_release = "/my/deploy/dir/releases/73219b87e977d9c7ba1aa57e9ad1d88fa91a0ec2"
    expect(@provider.all_releases).to eq([@expected_release_dir, second_release])
    @provider.cleanup!

    allow(@provider).to receive(:release_slug).and_return("8a3195bf3efa246f743c5dfa83683201880f935c")
    @provider.load_current_resource
    @provider.cleanup!
    expect(@provider.all_releases).to eq([second_release, @expected_release_dir])
  end

  it "removes a release from the file cache when it's deleted by :cleanup!" do
    release_paths = %w{first second third fourth fifth}.map do |release_name|
      "/my/deploy/dir/releases/#{release_name}"
    end
    release_paths.each do |release_path|
      @provider.send(:release_created, release_path)
    end
    expect(@provider.all_releases).to eq(release_paths)

    allow(FileUtils).to receive(:rm_rf)
    @provider.cleanup!

    expected_release_paths = (%w{second third fourth fifth} << @resource.revision).map do |release_name|
      "/my/deploy/dir/releases/#{release_name}"
    end

    expect(@provider.all_releases).to eq(expected_release_paths)
  end

  it "regenerates the file cache if it's not available" do
    oldest = "/my/deploy/dir/releases/oldest"
    latest = "/my/deploy/dir/releases/latest"
    expect(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return([latest, oldest])
    expect(::File).to receive(:ctime).with(oldest).and_return(Time.now - 10)
    expect(::File).to receive(:ctime).with(latest).and_return(Time.now - 1)
    expect(@provider.all_releases).to eq([oldest, latest])
  end

end
