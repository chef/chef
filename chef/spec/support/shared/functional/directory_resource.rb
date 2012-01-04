#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

shared_examples_for "a directory resource" do
  context "when the target directory does not exist" do
    it "creates the directory when the :create action is run" do
      resource.run_action(:create)
      File.should exist(path)
    end

    it "recursively creates required directories if requested" do
      resource.recursive(true)
      recursive_path = File.join(path, 'red-headed-stepchild')
      resource.path(recursive_path)
      resource.run_action(:create)
      File.should exist(path)
      File.should exist(recursive_path)
    end
  end

  context "when the target directory exists" do
    before(:each) do
      FileUtils.mkdir(path)
    end

    it "does not re-create the directory" do
      resource.run_action(:create)
      File.should exist(path)
    end

    it "deletes the directory when the :delete action is run" do
      resource.run_action(:delete)
      File.should_not exist(path)
    end

    it "recursively deletes directories if requested" do
      FileUtils.mkdir(File.join(path, 'red-headed-stepchild'))
      resource.recursive(true)
      resource.run_action(:delete)
      File.should_not exist(path)
    end
  end
end

shared_context Chef::Resource::Directory do
  let(:path) do
    File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname(directory_base, nil))
  end

  after(:each) do
    FileUtils.rm_r(path) if File.exists?(path)
  end
end
