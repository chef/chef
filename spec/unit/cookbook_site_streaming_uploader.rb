#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'spec_helper'

require 'chef/cookbook_site_streaming_uploader'

class FakeTempfile
  def initialize(basename)
    @basename = basename
  end

  def close
  end

  def path
    "#{@basename}.ZZZ"
  end

end

describe Chef::CookbookSiteStreamingUploader do

  describe "create_build_dir" do

    before(:each) do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, 'cookbooks'))
      @loader = Chef::CookbookLoader.new(@cookbook_repo)
      @loader.load_cookbooks
      File.stub(:unlink).and_return()
    end

    it "should create the cookbook tmp dir" do
      cookbook = @loader[:openldap]
      files_count = Dir.glob(File.join(@cookbook_repo, cookbook.name.to_s, '**', '*'), File::FNM_DOTMATCH).count { |file| File.file?(file) }

      Tempfile.should_receive(:new).with("chef-#{cookbook.name}-build").and_return(FakeTempfile.new("chef-#{cookbook.name}-build"))
      FileUtils.should_receive(:mkdir_p).exactly(files_count + 1).times
      FileUtils.should_receive(:cp).exactly(files_count).times
      Chef::CookbookSiteStreamingUploader.create_build_dir(cookbook)
    end

  end # create_build_dir

end

