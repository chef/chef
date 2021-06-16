#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "chef/knife/cookbook_upload"

describe "knife cookbook upload", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:cb_dir) { "#{@repository_dir}/cookbooks" }

  when_the_chef_server "is empty" do
    when_the_repository "has a cookbook" do
      before do
        file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0")
      end

      it "knife cookbook upload uploads the cookbook" do
        knife("cookbook upload x -o #{cb_dir}").should_succeed stderr: <<~EOM
          Uploading x            [1.0.0]
          Uploaded 1 cookbook.
        EOM
      end

      it "knife cookbook upload --freeze uploads and freezes the cookbook" do
        knife("cookbook upload x -o #{cb_dir} --freeze").should_succeed stderr: <<~EOM
          Uploading x            [1.0.0]
          Uploaded 1 cookbook.
        EOM
        # Modify the file, attempt to reupload
        file "cookbooks/x/metadata.rb", 'name "x"; version "1.0.0"#different'
        knife("cookbook upload x -o #{cb_dir} --freeze").should_fail stderr: <<~EOM
          Uploading x              [1.0.0]
          ERROR: Version 1.0.0 of cookbook x is frozen. Use --force to override.
          WARNING: Not updating version constraints for x in the environment as the cookbook is frozen.
          ERROR: Failed to upload 1 cookbook.
        EOM
      end
    end

    when_the_repository "has a cookbook that depends on another cookbook" do
      before do
        file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0", "\ndepends 'y'")
        file "cookbooks/y/metadata.rb", cb_metadata("y", "1.0.0")
      end

      it "knife cookbook upload --include-dependencies uploads both cookbooks" do
        knife("cookbook upload --include-dependencies x -o #{cb_dir}").should_succeed stderr: <<~EOM
          Uploading x            [1.0.0]
          Uploading y            [1.0.0]
          Uploaded 2 cookbooks.
        EOM
      end

      it "knife cookbook upload fails due to missing dependencies" do
        knife("cookbook upload x -o #{cb_dir}").should_fail stderr: <<~EOM
          Uploading x            [1.0.0]
          ERROR: Cookbook x depends on cookbooks which are not currently
          ERROR: being uploaded and cannot be found on the server.
          ERROR: The missing cookbook(s) are: 'y' version '>= 0.0.0'
        EOM
      end

      it "knife cookbook upload -a uploads both cookbooks" do
        knife("cookbook upload -a -o #{cb_dir}").should_succeed stderr: <<~EOM
          Uploading x            [1.0.0]
          Uploading y            [1.0.0]
          Uploaded all cookbooks.
        EOM
      end
    end

    when_the_repository "has cookbook metadata without name attribute in metadata file" do
      before do
        file "cookbooks/x/metadata.rb", cb_metadata(nil, "1.0.0")
      end

      it "knife cookbook upload x " do
        expect { knife("cookbook upload x -o #{cb_dir}") }.to raise_error(Chef::Exceptions::MetadataNotValid)
      end
    end

    when_the_repository "has cookbooks at multiple paths" do

      let(:cb_dir_first) do
        File.join(@repository_dir, "cookbooks")
          .gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
      end

      let(:cb_dir_second) do
        File.join(@repository_dir, "test_cookbooks")
          .gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
      end

      before(:each) do
        file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0")
        file "test_cookbooks/y/metadata.rb", cb_metadata("y", "1.0.0")
      end

      it "knife cookbook upload with -o or --cookbook-path" do
        knife("cookbook upload x y -o #{cb_dir_first}#{File::PATH_SEPARATOR}#{cb_dir_second}").should_succeed stderr: <<~EOM
          Uploading x            [1.0.0]
          Uploading y            [1.0.0]
          Uploaded 2 cookbooks.
        EOM
      end

    end
  end
end
